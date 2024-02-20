#!/bin/bash

SCRIPTNAME="$(basename "$0")"
SHORT_NAME="${SCRIPTNAME%.*}"
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_DIR="$(basename $SCRIPT_PATH)"
VERSION="1.1.2"
LOGFILE="/tmp/lacework-deploy.txt"

# output errors should be listed as warnings
export TF_WARN_OUTPUT_ERRORS=1

info(){
cat <<EOI
$SCRIPTNAME ($VERSION)

EOI
}

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] [--workspace-summary] [--scenarios-path=SCENARIOS_PATH] [--sso-profile=SSO_PROFILE] --workspace=WORK --action=ACTION --parallelism=PARALLELISM

-h                      print this message and exit
--workspace-summary     print a count of resources per workspace
--workspace             the scenario to use
--scenarios-path        the custom scenarios directory path (default: ../scenarios)
--action                terraform actions (i.e. show, plan, apply, refresh, destroy)
--sso-profile           specify an sso login profile
--parallelism           set the terraform parallelism parameter (default: 20 - small number can reduce memory footprint but increase duration)
--refresh-on-plan       set the terraform plan argument refresh=true (default: false)
EOH
    exit 1
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

workspace_summary(){
    echo "finding all active workspaces - this may take some time..."
    providers=("aws" "gcp" "azure")
    
    for provider in "${providers[@]}"
    do
        # Change directory to the provider's directory
        cd "${SCRIPT_PATH}/${provider}"

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
    -f=*|--tfplan=*)
        PLANFILE="${i#*=}"
        shift # past argument=value
        ;;
    -c=*|--parallelism=*)
        PARALLELISM="${i#*=}"
        shift # past argument=value
        ;;
    -r|--refresh-on-plan)
        REFRESH_ON_PLAN="-refresh=true"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

# set current working directory to the script directory
cd $SCRIPT_PATH

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

if [ -z ${PARALLELISM} ]; then
    PARALLELISM=20
    infomsg "--parallelism not set, using default ${PARALLELISM}"
fi

if [ -z ${REFRESH_ON_PLAN} ]; then
    REFRESH_ON_PLAN="${REFRESH_ON_PLAN}"
    infomsg "--refresh-on-plan not set, using default ${REFRESH_ON_PLAN}"
fi

infomsg "Setting working directory to script directory: $SCRIPT_PATH"
cd $SCRIPT_PATH

# set provider to first segement of workspace name
CSP=$(echo ${WORK} | awk -F '-' '{ print $1 }')

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

check_tf_apply(){
    if [ ${1} -eq 0 ]; then
        warnmsg "No changes, not applying"
    elif [ ${1} -eq 1 ]; then
        errmsg "Terraform plan failed"
        exit 1
    elif [ ${1} -eq 2 ]; then
        if [ "apply" = "${2}" ]; then
            infomsg "Changes required, applying"
            if command_exists tf-summarize > /dev/null; then
                infomsg "tf-summarize found creating: ${DEPLOYMENT}-plan.txt"
                (
                    set -o pipefail
                    terraform show -json -no-color ${PLANFILE} | tf-summarize > "${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt" 
                )
                ERR=$?
            else
                infomsg "tf-summarize not found using terraform show: ${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt"
                (
                    set -o pipefail
                    terraform show -no-color ${PLANFILE} > "${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt"
                )
                ERR=$?
            fi
            infomsg "Terraform summary result: $ERR"
            
            infomsg "Running: terraform apply -input=false -no-color ${3}"
            (
                set -o pipefail
                terraform apply -parallelism=$PARALLELISM -input=false -no-color ${3} 2>&1 >> $LOGFILE
            )
            ERR=$?
            infomsg "Terraform result: $ERR"
            if [ $ERR -ne 0 ] || grep "Error: " $LOGFILE; then
                errmsg "Terraform failed: ${ERR}"
                exit 1
            fi
        else
            warnmsg "Plan only, not applying"
        fi
    fi
}

get_tfvar_value() {
    local tfvars_file="$1"
    local key="$2"
    
    if [ ! -f "$tfvars_file" ]; then
        echo "Error: $tfvars_file not found"
        return 1
    fi

    local value=$(grep -E "^$key\s*=" "$tfvars_file" | sed -E 's/^[^=]*= *["'\'']*//;s/["'\'']* *$//')

    if [ -n "$value" ]; then
        echo "$value"
    else
        echo "Key '$key' not found in $tfvars_file"
        return 1
    fi
}

# get the deployment unique id
tfvars_file="$SCRIPT_PATH/env_vars/variables-${WORK}.tfvars"
infomsg "Retrieving deployment id from: ${tfvars_file}"
export DEPLOYMENT=$(get_tfvar_value "$tfvars_file" "deployment")
if [ $? -ne 0 ]; then
    errmsg "Failed to retrieve deployment id from:  ${tfvars_file}"
    exit 1
fi

# set plan file
if [ -z ${PLANFILE} ]; then
    PLANFILE="build.tfplan"
fi

echo "ACTION            = ${ACTION}"
echo "LOCAL_BACKEND     = ${LOCAL_BACKEND}"
echo "VARS              = ${VARS}"
echo "CSP               = ${CSP}"
echo "SCENARIOS_PATH    = ${SCENARIOS_PATH}"
echo "DEPLOYMENT        = ${DEPLOYMENT}"
echo "PLANFILE          = ${PLANFILE}"
echo "PARALLELISM       = ${PARALLELISM}"
echo "REFRESH_ON_PLAN   = ${REFRESH_ON_PLAN}"

# change directory to provider directory
cd $CSP

# check for sso logged out session
if [[ "$CSP" == "aws" ]]; then
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

# stage kubeconfig
infomsg "Staging kubeconfig files..."
CONFIG_FILES=('config' "$CSP-attacker-$DEPLOYMENT-kubeconfig" "$CSP-target-$DEPLOYMENT-kubeconfig")
if [ ! -d "$HOME/.kube" ]; then
    infomsg "$HOME/.kube directory not found - creating..."
    mkdir -p "$HOME/.kube"
fi
# for eks we need to ensure that if kubeconfig is wiped between runs (e.g. CICD) that we repopulate as best we can
if [[ "$CSP" == "aws" ]]; then
    export ATTACKER_AWS_PROFILE=$(get_tfvar_value "$tfvars_file" "attacker_aws_profile")
    export ATTACKER_AWS_REGION=$(get_tfvar_value "$tfvars_file" "attacker_aws_region")
    export ATTACKER_EKS_ENABLED=$(cat $SCENARIOS_PATH/$WORK/attacker/infrastructure.json| jq -r 'try .context.aws.eks.enabled catch false')
    export TARGET_AWS_PROFILE=$(get_tfvar_value "$tfvars_file" "target_aws_profile")
    export TARGET_AWS_REGION=$(get_tfvar_value "$tfvars_file" "target_aws_region")
    export TARGET_EKS_ENABLED=$(cat $SCENARIOS_PATH/$WORK/target/infrastructure.json| jq -r 'try .context.aws.eks.enabled catch false')
    cat <<EOF
ATTACKER_AWS_PROFILE=$ATTACKER_AWS_PROFILE
ATTACKER_AWS_REGION=$ATTACKER_AWS_REGION
ATTACKER_EKS_ENABLED=$ATTACKER_EKS_ENABLED
TARGET_AWS_PROFILE=$TARGET_AWS_PROFILE
TARGET_AWS_REGION=$TARGET_AWS_REGION
TARGET_EKS_ENABLED=$TARGET_EKS_ENABLED
EOF
    if [[ "$ATTACKER_EKS_ENABLED" == "true" ]]; then 
        echo "EKS in attacker scenario enabled..."
        if ! command -v yq; then
            curl -LJ https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq &&\
            chmod +x /usr/local/bin/yq
        fi
        echo "Found yq: $(command -v yq)"
        CLUSTERS=$(aws eks list-clusters --profile=$ATTACKER_AWS_PROFILE --region=$ATTACKER_AWS_REGION --output=json)
        for CLUSTER in $(echo $CLUSTERS| jq -r --arg DEPLOYMENT "$DEPLOYMENT" '.clusters[] | select(endswith((["-",$DEPLOYMENT]|join(""))))'); do
            echo "Found cluster: $CLUSTER"
            aws eks update-kubeconfig --profile=$ATTACKER_AWS_PROFILE --name="$CLUSTER" --region=$ATTACKER_AWS_REGION
            aws eks update-kubeconfig --profile=$ATTACKER_AWS_PROFILE --name="$CLUSTER" --region=$ATTACKER_AWS_REGION --kubeconfig="$HOME/.kube/$CSP-attacker-$DEPLOYMENT-kubeconfig"
            echo "Adding profile and region context to kubeconfig..."
            yq -i -r '(.users[] | select(endswith("strenv(DEPLOYMENT)")|.user.exec.env[0].name) = "AWS_PROFILE"' -i "$HOME/.kube/config"
            echo "Add env AWS_PROFILE to default kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(endswith("strenv(DEPLOYMENT)")|.user.exec.env[0].value) = strenv(ATTACKER_AWS_PROFILE)' -i "$HOME/.kube/config"
            echo "Add env AWS_PROFILE value to default kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(endswith("strenv(DEPLOYMENT)")|.user.exec.env[1].name) = "AWS_REGION"' -i "$HOME/.kube/config"
            echo "Add env AWS_REGION to default kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(endswith("strenv(DEPLOYMENT)")|.user.exec.env[1].value) = strenv(ATTACKER_AWS_REGION)' -i "$HOME/.kube/config"
            echo "Add env AWS_REGION value to default kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(endswith("strenv(DEPLOYMENT)")|.user.exec.env[0].name) = "AWS_PROFILE"' -i "$HOME/.kube/$CSP-attacker-$DEPLOYMENT-kubeconfig"
            echo "Add env AWS_PROFILE to deployment kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(endswith("strenv(DEPLOYMENT)")|.user.exec.env[0].value) = strenv(ATTACKER_AWS_PROFILE)' -i "$HOME/.kube/$CSP-attacker-$DEPLOYMENT-kubeconfig"
            echo "Add env AWS_PROFILE value to deployment kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(endswith("strenv(DEPLOYMENT)")|.user.exec.env[1].name) = "AWS_REGION"' -i "$HOME/.kube/$CSP-attacker-$DEPLOYMENT-kubeconfig"
            echo "Add env AWS_REGION to deployment kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(endswith("strenv(DEPLOYMENT)")|.user.exec.env[1].value) = strenv(ATTACKER_AWS_REGION)' -i "$HOME/.kube/$CSP-attacker-$DEPLOYMENT-kubeconfig"
            echo "Add env AWS_REGION value to deployment kubeconfig - Result: $?"
        done
    fi
    if [[ "$TARGET_EKS_ENABLED" == "true" ]]; then 
        echo "EKS in target scenario enabled..."
        if ! command -v yq; then
            curl -LJ https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq &&\
            chmod +x /usr/local/bin/yq
        fi
        echo "Found yq: $(command -v yq)"
        CLUSTERS=$(aws eks list-clusters --profile=$TARGET_AWS_PROFILE --region=$TARGET_AWS_REGION)
        for CLUSTER in $(echo $CLUSTERS | jq -r --arg DEPLOYMENT "$DEPLOYMENT" '.clusters[] | select(endswith((["-",$DEPLOYMENT]|join(""))))'); do
            echo "Found cluster: $CLUSTER"
            aws eks update-kubeconfig --profile=$TARGET_AWS_PROFILE --name="$CLUSTER" --region=$TARGET_AWS_REGION
            aws eks update-kubeconfig --profile=$TARGET_AWS_PROFILE --name="$CLUSTER" --region=$TARGET_AWS_REGION --kubeconfig="$HOME/.kube/$CSP-target-$DEPLOYMENT-kubeconfig"
            yq -i -r '(.users[] | select(.name | test(map("-", strenv(DEPLOYMENT), "$") | join(""))) | .user.exec.env[0].name) = "AWS_PROFILE"' -i "$HOME/.kube/config"
            echo "Add env AWS_PROFILE to default kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(.name | test(map("-", strenv(DEPLOYMENT), "$") | join(""))) | .user.exec.env[0].value) = strenv(TARGET_AWS_PROFILE)' -i "$HOME/.kube/config"
            echo "Add env AWS_PROFILE value to default kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(.name | test(map("-", strenv(DEPLOYMENT), "$") | join(""))) | .user.exec.env[1].name) = "AWS_REGION"' -i "$HOME/.kube/config"
            echo "Add env AWS_REGION to default kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(.name | test(map("-", strenv(DEPLOYMENT), "$") | join(""))) | .user.exec.env[1].value) = strenv(TARGET_AWS_REGION)' -i "$HOME/.kube/config"
            echo "Add env AWS_REGION value to default kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(.name | test(map("-", strenv(DEPLOYMENT), "$") | join(""))) | .user.exec.env[0].name) = "AWS_PROFILE"' -i "$HOME/.kube/$CSP-target-$DEPLOYMENT-kubeconfig"
            echo "Add env AWS_PROFILE to deployment kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(.name | test(map("-", strenv(DEPLOYMENT), "$") | join(""))) | .user.exec.env[0].value) = strenv(TARGET_AWS_PROFILE)' -i "$HOME/.kube/$CSP-target-$DEPLOYMENT-kubeconfig"
            echo "Add env AWS_PROFILE value to deployment kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(.name | test(map("-", strenv(DEPLOYMENT), "$") | join(""))) | .user.exec.env[1].name) = "AWS_REGION"' -i "$HOME/.kube/$CSP-target-$DEPLOYMENT-kubeconfig"
            echo "Add env AWS_REGION to deployment kubeconfig - Result: $?"
            yq -i -r '(.users[] | select(.name | test(map("-", strenv(DEPLOYMENT), "$") | join(""))) | .user.exec.env[1].value) = strenv(TARGET_AWS_REGION)' -i "$HOME/.kube/$CSP-target-$DEPLOYMENT-kubeconfig"
            echo "Add env AWS_REGION value to deployment kubeconfig - Result: $?"
        done
    fi
fi
for CONFIG_FILE in "${CONFIG_FILES[@]}"; do
    infomsg "Creating kubeconfig: $HOME/.kube/$CONFIG_FILE"
    touch "$HOME/.kube/$CONFIG_FILE"
done

# truncate the log file
truncate -s0 $LOGFILE

# ensure formatting
terraform fmt -no-color

# set workspace
terraform workspace select -no-color -or-create=true ${WORK}

# update modules as required
terraform get -update=true -no-color
if [ -z ${LOCAL_BACKEND} ]; then
    infomsg "Running terraform init..."
    terraform init -backend-config=env_vars/init.tfvars -input=false -no-color >> $LOGFILE
    BACKEND="-var-file=env_vars/backend.tfvars"
else
    infomsg "Running terraform init..."
    terraform init -upgrade -input=false -no-color >> $LOGFILE
    BACKEND=""
fi;

if [ "show" = "${ACTION}" ]; then
    echo "Running: terraform show"
    if command_exists tf-summarize > /dev/null; then
        infomsg "tf-summarize found creating: ${DEPLOYMENT}-plan.txt"
        (
            set -o pipefail
            terraform show -json -no-color ${PLANFILE} | tf-summarize | tee "${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt" 
        )
        ERR=$?
    else
        infomsg "tf-summarize not found using terraform show: ${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt"
        (
            set -o pipefail
            terraform show -no-color ${PLANFILE} > "${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt"
        )
        ERR=$?
        infomsg "See log for plan details: ${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt" 
    fi
    infomsg "Terraform show result: $ERR"
    CHANGE_COUNT=$(terraform show -json ${PLANFILE}  | jq -r '[.resource_changes[].change.actions | map(select(test("^no-op")|not)) | .[]]|length')
    infomsg "Resource updates: $CHANGE_COUNT"
elif [ "plan" = "${ACTION}" ]; then
    echo "Running: terraform plan ${REFRESH_ON_PLAN} ${DESTROY} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    (
        set -o pipefail
        terraform plan ${REFRESH_ON_PLAN} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode -compact-warnings -input=false -no-color 2>&1 >> $LOGFILE
    )
    ERR=$?
    infomsg "Terraform result: $ERR"
    if [ $ERR -ne 0 ] || grep "Error: " $LOGFILE; then
        ERR=1
        errmsg "Terraform failed: ${ERR}"
        exit $ERR
    fi
    if command_exists tf-summarize > /dev/null; then
        infomsg "tf-summarize found creating: ${DEPLOYMENT}-plan.txt"
        (
            set -o pipefail
            terraform show -json -no-color ${PLANFILE} | tf-summarize > "${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt" 
        )
        ERR=$?
    else
        infomsg "tf-summarize not found using terraform show: ${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt"
        (
            set -o pipefail
            terraform show -no-color ${PLANFILE} > "${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt"
        )
        ERR=$?
    fi
    infomsg "Terraform summary result: $ERR"
    CHANGE_COUNT=$(terraform show -json ${PLANFILE}  | jq -r '[.resource_changes[].change.actions | map(select(test("^no-op")|not)) | .[]]|length')
    infomsg "Resource updates: $CHANGE_COUNT"
elif [ "refresh" = "${ACTION}" ]; then
    echo "Running: terraform refresh ${BACKEND} ${VARS}"
    (
        set -o pipefail
        terraform refresh ${BACKEND} ${VARS} -compact-warnings -input=false -no-color 2>&1 >> $LOGFILE
    )
    ERR=$?
    infomsg "Terraform result: $ERR"
elif [ "apply" = "${ACTION}" ]; then        
    echo "Running: terraform plan ${REFRESH_ON_PLAN} ${DESTROY} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    (
        set -o pipefail
        terraform plan ${REFRESH_ON_PLAN} ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode -compact-warnings -input=false -no-color 2>&1 >> $LOGFILE
    )
    ERR=$?
    infomsg "Terraform result: $ERR"
    CHANGE_COUNT=$(terraform show -json ${PLANFILE}  | jq -r '[.resource_changes[].change.actions | map(select(test("^no-op")|not)) | .[]]|length')
    infomsg "Resource updates: $CHANGE_COUNT"
    if [[ $CHANGE_COUNT -gt 0 ]] && [[ ERR -ne 1 ]]; then ERR=2; fi
    check_tf_apply ${ERR} apply ${PLANFILE}
elif [ "destroy" = "${ACTION}" ]; then
    echo "Running: terraform plan ${REFRESH_ON_PLAN} -destroy ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode"
    (
        set -o pipefail
        terraform plan ${REFRESH_ON_PLAN} -destroy ${BACKEND} ${VARS} -out ${PLANFILE} -detailed-exitcode -compact-warnings -input=false -no-color 2>&1 >> $LOGFILE
    )
    ERR=$?
    infomsg "Terraform result: $ERR"
    CHANGE_COUNT=$(terraform show -json ${PLANFILE}  | jq -r '[.resource_changes[].change.actions | map(select(test("^no-op")|not)) | .[]]|length')
    infomsg "Resource updates: $CHANGE_COUNT"
    if [[ $CHANGE_COUNT -gt 0 ]] && [[ ERR -ne 1 ]]; then ERR=2; fi
    
    # additional check because plan doesn't return 0 for -destory
    if [ $ERR -eq 1 ] || grep "Error: " $LOGFILE; then
        ERR=1
        errmsg "Terraform failed: ${ERR}"
        exit $ERR
    else
        if command_exists tf-summarize > /dev/null; then
            infomsg "tf-summarize found creating: ${DEPLOYMENT}-plan.txt"
            (
                set -o pipefail
                terraform show -json -no-color ${PLANFILE} | tf-summarize | tee "${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt" 
            )
            ERR=$?
        else
            infomsg "tf-summarize not found using terraform show: ${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt"
            (
                set -o pipefail
                terraform show -no-color ${PLANFILE} > "${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt"
            )
            ERR=$?
            infomsg "See log for plan details: ${SCRIPT_PATH}/${DEPLOYMENT}-plan.txt" 
        fi
        echo "Running: terraform apply -destroy -compact-warnings -auto-approve -input=false -no-color ${PLANFILE}"
        (
            set -o pipefail 
            terraform apply -parallelism=$PARALLELISM -destroy -compact-warnings -auto-approve -input=false -no-color ${PLANFILE} 2>&1 >> $LOGFILE
        )
        ERR=$?
        infomsg "Terraform result: $ERR"
        exit $ERR
    fi
fi

echo "Done."
exit 0