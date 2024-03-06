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
--parallelism           set the terraform parallelism parameter (default: 10 - smaller number can reduce memory footprint but increase duration)
--no-refresh-on-plan    set the terraform plan argument refresh=true (default: true - this can reduce plan timing but cause misaligned plan)
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
    -n|--no-refresh-on-plan)
        NO_REFRESH_ON_PLAN="-refresh=false"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

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
    PARALLELISM=10
    infomsg "--parallelism not set, using default ${PARALLELISM}"
fi

if [ -z ${NO_REFRESH_ON_PLAN} ]; then
    NO_REFRESH_ON_PLAN="-refresh=true"
    infomsg "--refresh-on-plan not set, using default ${NO_REFRESH_ON_PLAN}"
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
echo "REFRESH_ON_PLAN   = ${NO_REFRESH_ON_PLAN}"

if [ "${ACTION}" == "destroy" ]; then
    TERRAFORM_DESTROY_ARGS="-destroy"
else
    TERRAFORM_DESTROY_ARGS=""
fi
TERRAFORM_PLAN_ARGS="${BACKEND} ${VARS} ${TERRAFORM_DESTROY_ARGS} -out ${PLANFILE} -detailed-exitcode -compact-warnings"
TERRAFORM_COMMON_ARGS="-parallelism=${PARALLELISM} ${NO_REFRESH_ON_PLAN} -input=false -no-color"
TERRAFORM_APPLY_ARGS="-auto-approve ${TERRAFORM_DESTROY_ARGS} ${PLANFILE}"

# change directory to provider directory
cd $CSP

run_terraform_plan() {
    echo "Running: terraform plan ${TERRAFORM_COMMON_ARGS} ${TERRAFORM_PLAN_ARGS}"
    (
        set -o pipefail
        terraform plan ${TERRAFORM_COMMON_ARGS} ${TERRAFORM_PLAN_ARGS} 2>&1 | tee -a $LOGFILE
    )
    return $?
}

run_terraform_apply() {
    echo "Running: terraform apply -input=false -no-color ${APPLY_ARGS}"
    (
        set -o pipefail
        terraform apply ${TERRAFORM_COMMON_ARGS} ${TERRAFORM_APPLY_ARGS}  2>&1 | tee -a $LOGFILE
    )
    return $?
}

run_terraform_show() {
    if command_exists tf-summarize; then
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
}

check_for_errors() {
    local LOCAL_ACTION=$1
    local ERR_CODE=$2
    local ERROR_MSG=$3
    
    
    if [ "${LOCAL_ACTION}" == "plan" ]; then
        if ( [ $ERR_CODE -ne 2 ] && [ $ERR_CODE -ne 0 ] ) || grep "Error: " $LOGFILE; then
            errmsg "$ERROR_MSG: ${ERR_CODE}"
            exit $ERR_CODE
        fi
    else
        if ( [ $ERR_CODE -ne 0 ] ) || grep "Error: " $LOGFILE; then
            errmsg "$ERROR_MSG: ${ERR_CODE}"
            exit $ERR_CODE
        fi
    fi
}

# check for sso logged out session
check_session(){
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
}

# stage kubeconfig
stage_kubeconfig() {
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
        if ([[ "$ATTACKER_EKS_ENABLED" == "true" ]] || [[ "$TARGET_EKS_ENABLED" == "true" ]]) && ! command -v yq; then 
            curl -LJ https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq &&\
            chmod +x /usr/local/bin/yq
            echo "Found yq: $(command -v yq)"
        fi
        if [[ "$ATTACKER_EKS_ENABLED" == "true" ]]; then 
            echo "EKS in attacker scenario enabled..."
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
}

# truncate the log file
truncate -s0 $LOGFILE

# ensure user session (sso) is valid and refresh as required
check_session

# prep kubeconfig files for kubernetes provider
stage_kubeconfig

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
    run_terraform_show
    CHANGE_COUNT=$(terraform show -json ${PLANFILE} | jq -r '[.resource_changes[].change.actions | map(select(test("^no-op")|not)) | .[]]|length' || echo 0)
    infomsg "Resource updates: $CHANGE_COUNT"
elif [ "plan" = "${ACTION}" ]; then
    run_terraform_plan
    ERR=$?
    infomsg "Terraform plan result: $ERR"
    check_for_errors "plan" $ERR "Initial Terraform plan failed"
    CHANGE_COUNT=$(terraform show -json ${PLANFILE}  | jq -r '[.resource_changes[].change.actions | map(select(test("^no-op")|not)) | .[]]|length' || echo 0)
    infomsg "Resource updates: $CHANGE_COUNT"
    run_terraform_show
elif [ "refresh" = "${ACTION}" ]; then
    stage_kubeconfig
    echo "Running: terraform refresh ${BACKEND} ${VARS}"
    (
        set -o pipefail
        terraform refresh ${BACKEND} ${VARS} -compact-warnings -input=false -no-color >> $LOGFILE 2>&1
    )
    ERR=$?
    infomsg "Terraform result: $ERR"
elif [ "apply" = "${ACTION}" ]; then        
    run_terraform_plan
    ERR=$?
    infomsg "Terraform plan result: $ERR"
    check_for_errors "plan" $ERR "Initial Terraform plan failed"

    CHANGE_COUNT=$(terraform show -json ${PLANFILE}  | jq -r '[.resource_changes[].change.actions | map(select(test("^no-op")|not)) | .[]]|length' || echo 0)
    infomsg "Resource updates: $CHANGE_COUNT"

    run_terraform_show
    
    if [ $ERR -eq 0 ] && [ $CHANGE_COUNT -eq 0 ]; then
        warnmsg "no updates required"
    else
        # Run initial Terraform apply
        run_terraform_apply
        ERR=$?
        infomsg "Terraform apply result: $ERR"

        # Check for Kubernetes readiness errors
        if [ $ERR -ne 0 ] && grep "dial tcp \[\:\:1\]\:80\: connect\: connection refused" $LOGFILE; then
            infomsg "Some Kubernetes resources were not ready during deploy - a second apply is required..."
            stage_kubeconfig

            # Retry Terraform plan and apply
            run_terraform_plan
            ERR=$?
            infomsg "Retried Terraform plan result: $ERR"
            check_for_errors "plan" $ERR "Retried Terraform plan failed"
            
            run_terraform_apply
            ERR=$?
            check_for_errors "apply" $ERR "Retried Terraform apply failed"
        else
            check_for_errors "apply" $ERR "Terraform apply failed" 
        fi
    fi
elif [ "destroy" = "${ACTION}" ]; then
    run_terraform_plan
    ERR=$?
    infomsg "Terraform plan result: $ERR"
    check_for_errors "plan" $ERR "Initial Terraform plan failed"

    CHANGE_COUNT=$(terraform show -json ${PLANFILE}  | jq -r '[.resource_changes[].change.actions | map(select(test("^no-op")|not)) | .[]]|length' || echo 0)
    infomsg "Resource updates: $CHANGE_COUNT"

    run_terraform_show
    
    if [ $ERR -eq 0 ] && [ $CHANGE_COUNT -eq 0 ]; then
        warnmsg "no updates required"
    else
        # Run initial Terraform apply
        run_terraform_apply
        ERR=$?
        check_for_errors "apply" $ERR "Terraform destroy failed"
        infomsg "Terraform destroy result: $ERR"
    fi
fi

echo "Done."
exit 0