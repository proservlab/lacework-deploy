#!/bin/bash

SCRIPTNAME="$(basename "$0")"
SHORT_NAME="${SCRIPTNAME%.*}"
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_DIR="$(basename $SCRIPT_PATH)"
VERSION="0.0.1"

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] [--profile] [--action=<generate|validate>] [--policy=<path to policy> ] --test-name=<TEST_NAME>

-h                      print this message and exit
--profile               the aws profile to use
--test-name             the name of the test folder. this will also be the traceable AWS_EXECUTION_ENV value.
--action                the action to take should be either generate or valiadate.
--policy                if action is validate a policy path is required here. this is the iam role policy 
                        that will be used to validate the policy has valid permission to apply.
EOH
    exit 1
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
    -p=*|--profile=*)
        SSO_PROFILE="--profile=${i#*=}"
        PROFILE="--profile=${i#*=}"
        VARS="-var=default_aws_profile=${i#*=}"
        shift # past argument=value
        ;;
    -t=*|--test-name=*)
        TEST_NAME="${i#*=}"
        shift # past argument=value
        ;;
    -a=*|--action=*)
        ACTION="${i#*=}"
        shift # past argument=value
        ;;
    -f=*|--policy=*)
        POLICY="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

if [ -z ${TEST_NAME} ]; then
    errmsg "Required value --test-name missing."
    help
fi

if [ -z ${ACTION} ]; then
    infomsg "No action set, default generate will be used."
    ACTION="generate"
elif [ "${ACTION}" != "validate" ] && [ "${ACTION}" != "generate" ]; then
    errmsg "Invalid action: --action should be one of generate or validate"
    help
elif [ "${ACTION}" == "validate" ] && [ -z $POLICY ]; then
    warnmsg "A policy file must be specified when using validate. Will attempt to use ${TEST_NAME}.json"
    POLICY="${SCRIPT_PATH}/${TEST_NAME}.json"
fi

# check to see if the policy file exists
if ! [ -z ${POLICY} ] && ! [ -f "${POLICY}" ]; then
    errmsg "Policy file not found: ${POLICY}"
    exit 1
fi

#LOGFILE=/tmp/example.log
function log {
    echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1"
    # echo `date -u +"%Y-%m-%dT%H:%M:%SZ"`" $1" >> $LOGFILE
}
# truncate -s 0 $LOGFILE

# Function to check if a command is installed
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if aws-cli is installed and install if not
check_jq() {
    if command_exists jq &> /dev/null; then
        infomsg "jq installed."
    else
        infomsg "jq is not installed."
        
        read -p "> Would you like to install it? (y/n): " install_jq
        case "$install_jq" in
            y|Y )
                if [[ $(uname -s) == "Linux" ]]; then
                    infomsg "installing jq for linux..."
                    sudo apt-get update
                    sudo apt-get install -y jq
                elif [[ $(uname -s) == "Darwin" ]]; then
                    infomsg "installing jq for mac..."
                    if ! command_exists brew &> /dev/null; then
                        errmsg "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install jq
                else
                    errmsg "Unsupported operating system. Please install aws-cli manually."
                    exit 1
                fi
                ;;
            n|N )
                errmsg "jq will not be installed."
                errmsg "jq is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                errmsg "invalid input. jq will not be installed"
                errmsg "jq is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

check_terraform_cli() {
    if command_exists terraform &> /dev/null; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            installed_version=$(terraform version | head -n1 | grep -oP 'v\d+\.\d+\.\d+')
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            installed_version=$(terraform version | head -n1 | grep -oE 'v\d+\.\d+\.\d+')
        fi
        required_version="v1.4.0"
        if [[ "$(printf '%s\n' "$required_version" "$installed_version" | sort -V | head -n1)" != "$required_version" ]]; then
            infomsg "terraform version $required_version or higher is required."
            
            read -p "> do you want to upgrade the terraform cli version to 1.4.2? (y/n) " upgrade_terraform_cli
            case "$upgrade_terraform_cli" in
                y|Y )
                    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                        wget https://releases.hashicorp.com/terraform/1.4.2/terraform_1.4.2_linux_amd64.zip
                        unzip terraform_1.4.2_linux_amd64.zip
                        sudo mv terraform /usr/local/bin/
                        rm terraform_1.4.2_linux_amd64.zip
                    elif [[ "$OSTYPE" == "darwin"* ]]; then
                        # check if brew is installed
                        if ! command_exists brew &> /dev/null
                        then
                            errmsg "brew is not installed. please install brew first: https://brew.sh/"
                            exit 1
                        fi
                        # install for macOS using brew
                        brew install terraform
                    else
                        errmsg "unsupported operating system."
                        errmsg "terraform version $required_version or higher is required. please install it manually."
                        exit 1
                    fi
                    ;;
                n|N )
                    errmsg "terraform cli will not be upgraded."
                    errmsg "terraform version $required_version or higher is required. please install it manually."
                    exit 1
                    ;;
                * )
                    errmsg "terraform cli will not be upgraded."
                    errmsg "terraform version $required_version or higher is required. please install it manually."
                    exit 1
                    ;;
            esac
        else
            infomsg "terraform version $installed_version is installed and supported."
        fi
    else
        
        read -p "> terraform cli is not installed. do you want to install it? (y/n) " install_terraform_cli
        case "$install_terraform_cli" in
            y|Y )
                if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                    wget https://releases.hashicorp.com/terraform/1.4.2/terraform_1.4.2_linux_amd64.zip
                    unzip terraform_1.4.2_linux_amd64.zip
                    sudo mv terraform /usr/local/bin/
                    rm terraform_1.4.2_linux_amd64.zip
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                    # check if brew is installed
                    if ! command_exists brew &> /dev/null
                    then
                        errmsg "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    # install for macOS using brew
                    brew install terraform
                else
                    errmsg "unsupported operating system."
                    errmsg "terraform cli is required to proceed. please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                errmsg "terraform cli will not be installed."
                errmsg "terraform cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                errmsg "terraform cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

check_aws_cli() {
    if command_exists aws &> /dev/null; then
        infomsg "aws-cli installed."
    else
        infomsg "aws-cli is not installed."
        
        read -p "> Would you like to install it? (y/n): " install_aws_cli
        case "$install_aws_cli" in
            y|Y )
                if [[ $(uname -s) == "Linux" ]]; then
                    infomsg "installing aws-cli for linux..."
                    sudo apt-get update
                    sudo apt-get install -y awscli
                elif [[ $(uname -s) == "Darwin" ]]; then
                    infomsg "installing aws-cli for mac..."
                    if ! command_exists brew &> /dev/null; then
                        errmsg "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install awscli
                else
                    errmsg "Unsupported operating system. Please install aws-cli manually."
                    exit 1
                fi
                ;;
            n|N )
                errmsg "aws cli will not be installed."
                errmsg "aws cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                errmsg "invalid input. aws cli will not be installed"
                errmsg "aws cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

cat <<-'EOM'
##########################################################################################################################
$$$$$$$$\                                                                                                     
\__$$  __|                                                                                                    
   $$ | $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$\   $$$$$$\   $$$$$$\   $$$$$$\  $$$$$$\$$$$\   $$$$$$\   $$$$$$$\ 
   $$ |$$  __$$\ $$  __$$\ $$  __$$\ \____$$\ $$  __$$\ $$  __$$\ $$  __$$\ $$  _$$  _$$\ $$  __$$\ $$  _____|
   $$ |$$$$$$$$ |$$ |  \__|$$ |  \__|$$$$$$$ |$$ /  $$ |$$$$$$$$ |$$ |  \__|$$ / $$ / $$ |$$$$$$$$ |\$$$$$$\  
   $$ |$$   ____|$$ |      $$ |     $$  __$$ |$$ |  $$ |$$   ____|$$ |      $$ | $$ | $$ |$$   ____| \____$$\ 
   $$ |\$$$$$$$\ $$ |      $$ |     \$$$$$$$ |$$$$$$$  |\$$$$$$$\ $$ |      $$ | $$ | $$ |\$$$$$$$\ $$$$$$$  |
   \__| \_______|\__|      \__|      \_______|$$  ____/  \_______|\__|      \__| \__| \__| \_______|\_______/ 
                                              $$ |                                                            
                                              $$ |                                                            
                                              \__|                                          
##########################################################################################################################    
EOM

log "Checking for pre-requisites..."
log "Checking for jq..."
check_jq

log "Checking for terraform cli..."
check_terraform_cli

log "Checking for aws cli..."
check_aws_cli

ATHENA_SETTINGS="${SCRIPT_PATH}/athena-settings.json"
PLANFILE="build.tfplan"
APPLY_WAIT_SECS=30

cat <<-EOF
TEST_NAME=${TEST_NAME}
PROFILE=${PROFILE}
APPLY_WAIT_SECS=${APPLY_WAIT_SECS}
EOF

log "Retriving athena settings..."
ATHENA_WORKGROUP_ID=$(jq -r '.athena_workgroup_name.value' ${ATHENA_SETTINGS})
ATHENA_CREATE_TABLE_QUERY=$(jq -r '.athena_create_table_named_query_id.value' ${ATHENA_SETTINGS})
NAMED_QUERY=$(aws athena get-named-query --named-query-id ${ATHENA_CREATE_TABLE_QUERY} ${PROFILE})
QUERY_STRING=$(echo $NAMED_QUERY | jq -r '.NamedQuery.QueryString')
DATABASE=$(echo $NAMED_QUERY | jq -r '.NamedQuery.Database')
WORKGROUP=$(echo $NAMED_QUERY | jq -r '.NamedQuery.WorkGroup')

# init
if ! [ -d "${SCRIPT_PATH}/${TEST_NAME}" ]; then 
    errmsg "Test directory not found: ${SCRIPT_PATH}/${TEST_NAME}"
    exit 1
fi
log "Change directory to: ${SCRIPT_PATH}/${TEST_NAME}"
cd ${SCRIPT_PATH}/${TEST_NAME}
log "Initializing Terraform..."
terraform init -upgrade

# generate
if [ "${ACTION}" == "generate" ]; then
    export AWS_EXECUTION_ENV="${TEST_NAME}"
    
    # apply
    log "Starting terrafrom apply..."
    terraform plan -out ${PLANFILE} ${VARS} -detailed-exitcode -compact-warnings
    ERR=$?
    if [ $ERR -eq 0 ]; then
        warnmsg "No changes, not applying"
    elif [ $ERR -eq 1 ]; then
        errmsg "Terraform plan failed"
        exit 1
    elif [ $ERR -eq 2 ]; then
        infomsg "Changes required, applying"
        terraform apply ${PLANFILE}
    fi

    # wait after successful apply
    log "Apply complete. Waiting ${APPLY_WAIT_SECS} seconds before destroy..."
    sleep ${APPLY_WAIT_SECS}

    # destroy
    log "Starting terraform destroy..."
    terraform plan -destroy -out ${PLANFILE} ${VARS} -detailed-exitcode -compact-warnings
    ERR=$?
    # additional check because plan doesn't return 0 for -destory
    if [ $ERR -eq 2 ]; then
        if terraform show -no-color ${PLANFILE} | grep -E "No changes. No objects need to be destroyed."; then
            ERR=0;
        else
            terraform destroy ${VARS} -compact-warnings -auto-approve
        fi
    fi

    # here we should use the query.py to 

# validate
elif [ "${ACTION}" == "validate" ]; then
    # create role first
    VARS="${VARS} -var=create_role=true -var=role_name=${TEST_NAME} -var=role_policy_path=${POLICY}"

    # apply
    log "Starting terrafrom apply to create role based on policy..."
    terraform plan -out ${PLANFILE} ${VARS} -detailed-exitcode -compact-warnings
    ERR=$?
    if [ $ERR -eq 0 ]; then
        warnmsg "No changes, not applying"
    elif [ $ERR -eq 1 ]; then
        errmsg "Terraform plan failed"
        exit 1
    elif [ $ERR -eq 2 ]; then
        infomsg "Changes required, applying"
        terraform apply ${PLANFILE}
    fi

    # wait after successful apply
    log "Apply create role complete. Waiting ${APPLY_WAIT_SECS} seconds before second stage..."
    sleep ${APPLY_WAIT_SECS}

    VARS="${VARS} -var=role_name=${TEST_NAME} -var=assume_role_apply=true -var=role_policy_path=${POLICY}"

    # apply
    log "Starting terrafrom apply with assumed role..."
    terraform plan -out ${PLANFILE} ${VARS} -detailed-exitcode -compact-warnings
    ERR=$?
    if [ $ERR -eq 0 ]; then
        warnmsg "No changes, not applying"
    elif [ $ERR -eq 1 ]; then
        errmsg "Terraform plan failed"
        exit 1
    elif [ $ERR -eq 2 ]; then
        infomsg "Changes required, applying"
        terraform apply ${PLANFILE}
    fi

    # wait after successful apply
    log "Apply complete. Waiting ${APPLY_WAIT_SECS} seconds before destroy..."
    sleep ${APPLY_WAIT_SECS}

    # destroy
    log "Starting terraform destroy..."
    terraform plan -destroy -out ${PLANFILE} ${VARS} -detailed-exitcode -compact-warnings
    ERR=$?
    # additional check because plan doesn't return 0 for -destory
    if [ $ERR -eq 2 ]; then
        if terraform show -no-color ${PLANFILE} | grep -E "No changes. No objects need to be destroyed."; then
            ERR=0;
        else
            terraform destroy ${VARS} -compact-warnings -auto-approve
        fi
    fi
fi

rm -f ${PLANFILE}
log "Action ${ACTION}: execution complete."
