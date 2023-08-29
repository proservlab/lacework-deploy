#!/bin/bash

SCRIPTNAME=$(basename $0)
VERSION="1.0.0"

# output errors should be listed as warnings
export TF_WARN_OUTPUT_ERRORS=1

info(){
cat <<EOI
$SCRIPTNAME ($VERSION)

EOI
}

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] [--workspace-summary] [--scenarios-path=SCENARIOS_PATH] --workspace=WORK --action=ACTION [--sso-profile]

-h                      print this message and exit
--workspace-summary     print a count of resources per workspace
--workspace             the scenario to use
--scenarios-path        the custom scenarios directory path (default is ../scenarios)
--action                terraform actions (i.e. show, plan, apply, refresh, destroy)
--sso-profile           specify an sso login profile
EOH
    exit 1
}

workspace_summary(){
    echo "finding all active workspaces - this may take some time..."
    providers=("aws" "gcp" "azure")

    for provider in "${providers[@]}"
    do
        # echo "Checking resources for $provider"
        
        # Change directory to the provider's directory
        cd $provider

        # Get the list of workspaces
        workspaces=($(terraform workspace list | tr -d '*'))

        for workspace in "${workspaces[@]}"
        do
            # Removing leading whitespace
            workspace=$(echo $workspace | sed -e 's/^[[:space:]]*//')

            #echo "Switching to workspace $workspace"
            terraform workspace select $workspace > /dev/null 2>&1

            # Use terraform state list to count resources
            resource_count=$(terraform state list 2>/dev/null | wc -l)
            if [ "$resource_count" -gt "0" ]; then
                echo "$workspace $resource_count"
            else
                if [ "$workspace" != "default" ]; then
                    echo "removing empty workspace: $workspace $resource_count"
                    terraform workspace select default > /dev/null 2>&1
                    terraform workspace delete $workspace > /dev/null 2>&1
                fi
            fi
        done

        # Change directory back to the parent directory
        cd ..
    done

    exit 0
}

infomsg(){
echo "INFO: ${1}"
}
warnmsg(){
echo "WARN: ${1}"
}
errmsg(){
echo "ERROR: ${1}"
}

for i in "$@"; do
  case $i in
    -h|--help)
        HELP="${i#*=}"
        shift # past argument=value
        help
        ;;
    -z|--workspace-summary)
        WORKSPACE="${i#*=}"
        shift # past argument=value
        workspace_summary
        ;;
    -a=*|--action=*)
        ACTION="${i#*=}"
        shift # past argument=value
        ;;
    -w=*|--workspace=*)
        WORK="${i#*=}"
        shift # past argument=value
        ;;
    -p=*|--sso-profile=*)
        SSO_PROFILE="--profile=${i#*=}"
        shift # past argument=value
        ;;
    -s=*|--scenarios-path=*)
        SCENARIOS_PATH="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

# check for required
if [ -z ${WORK} ]; then
    errmsg "Required option not set: --workspace"
    help
fi

if [ -z ${SSO_PROFILE} ]; then
    SSO_PROFILE=""
fi

# set the scenarios_path
if [ ! -z ${SCENARIOS_PATH} ]; then
    export TF_VAR_scenarios_path="${SCENARIOS_PATH}"
else
    SCENARIOS_PATH="../scenarios"
fi


if [ -z ${ACTION} ]; then
    errmsg "Required option not set: --action"
    help
elif [ "${ACTION}" != "destroy" ] && [ "${ACTION}" != "apply" ] && [ "${ACTION}" != "plan" ] && [ "${ACTION}" != "refresh" ] && [ "${ACTION}" != "show" ]; then
    errmsg "Invalid action: --action should be one of show, plan, apply, refresh or destroy"
    help
fi

# set provider to first segement of workspace name
PROVIDER=$(echo ${WORK} | awk -F '-' '{ print $1 }')

# use variables.tfvars if it exists
if [ -f "env_vars/variables.tfvars" ]; then
  VARS="-var-file=env_vars/variables.tfvars"
else
  VARS=""
fi

# look for work space variables
if [ -f "env_vars/variables-${WORK}.tfvars" ]; then
  VARS="${VARS} -var-file=env_vars/variables-${WORK}.tfvars"
else
  VARS="${VARS}"
fi

# force local back-end
LOCAL_BACKEND="true"

echo "ACTION            = ${ACTION}"
echo "LOCAL_BACKEND     = ${LOCAL_BACKEND}"
echo "VARS              = ${VARS}"
echo "PROVIDER          = ${PROVIDER}"
echo "SCENARIOS_PATH   = ${SCENARIOS_PATH}"

# check for sso logged out session
if [[ "$PROVIDER" == "aws" ]]; then
    session_check=$(aws sts get-caller-identity ${SSO_PROFILE} 2>&1)
    if echo $session_check | grep "The SSO session associated with this profile has expired or is otherwise invalid." > /dev/null 2>&1; then
        read -p "> aws sso session has expired - login now? (y/n): " login
        case "$login" in
            y|Y )
                aws sso login ${SSO_PROFILE}
                ;;
            n|N )
                errmsg "aws session expired - manual login required."
                exit 1
                ;;
            * )
                errmsg "aws session expired - manual login required."
                exit 1
                ;;
        esac
    fi
fi

# change directory to provider directory
cd $PROVIDER

# ensure formatting
terraform fmt

# set workspace
terraform workspace select ${WORK} || terraform workspace new ${WORK}

# update modules as required
terraform get -update=true
if [ -z ${LOCAL_BACKEND} ]; then
    terraform init -backend-config=env_vars/init.tfvars
    BACKEND="-var-file=env_vars/backend.tfvars"
else
    terraform init -upgrade
    BACKEND=""
fi;

check_tf_apply(){
    if [ ${1} -eq 0 ]; then
        warnmsg "No changes, not applying"
    elif [ ${1} -eq 1 ]; then
        errmsg "Terraform plan failed"
        exit 1
    elif [ ${1} -eq 2 ]; then
        if [ "apply" = "${2}" ]; then
            infomsg "Changes required, applying"
            # terraform show ${PLANFILE}
            terraform apply ${3}
        else
            warnmsg "Plan only, not applying"
        fi
    fi
}

# set plan file
PLANFILE="build.tfplan"

if [ "show" = "${ACTION}" ]; then
    echo "Running: terraform show"
    terraform show
elif [ "plan" = "${ACTION}" ]; then
    echo "Staging kubeconfig..."
    terraform apply ${BACKEND} ${VARS} -target=null_resource.kubeconfig -auto-approve -compact-warnings
    echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    terraform plan ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode -compact-warnings
    ERR=$?
    terraform show ${PLANFILE}
elif [ "plan" = "${ACTION}" ]; then
    echo "Staging kubeconfig..."
    terraform apply ${BACKEND} ${VARS} -target=null_resource.kubeconfig -auto-approve -compact-warnings
    echo "Running: terraform refresh ${BACKEND} ${VARS}"
    terraform refresh ${BACKEND} ${VARS} -compact-warnings
elif [ "apply" = "${ACTION}" ]; then        
    echo "Staging kubeconfig..."
    terraform apply ${BACKEND} ${VARS} -target=null_resource.kubeconfig -auto-approve -compact-warnings
    echo "Running: terraform plan ${DESTROY} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    terraform plan ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode -compact-warnings
    ERR=$?
    check_tf_apply ${ERR} apply ${PLANFILE}
elif [ "destroy" = "${ACTION}" ]; then
    echo "Running: terraform plan -destroy ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    terraform plan -destroy ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode -compact-warnings 
    ERR=$?
    # additional check because plan doesn't return 0 for -destory
    if [ $ERR -eq 2 ]; then
        if terraform show -no-color ${PLANFILE} | grep -E "No changes. No objects need to be destroyed."; then
            ERR=0;
        else
            terraform destroy ${BACKEND} ${VARS} -compact-warnings -auto-approve
        fi
    fi
fi
rm -f ${PLANFILE}

echo "Done."