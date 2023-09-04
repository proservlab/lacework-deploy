#!/bin/bash

SCRIPTNAME="$(basename "$0")"
SHORT_NAME="${SCRIPTNAME%.*}"
SCRIPT_PATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
SCRIPT_DIR="$(basename $SCRIPT_PATH)"
VERSION="0.0.1"

help(){
cat <<EOH
usage: $SCRIPTNAME [-h] [--profile] [--action=<apply|destroy>]

-h                      print this message and exit
--profile               the aws profile to use
--action                setup action (i.e. apply, destroy). default: apply
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
    -a=*|--action=*)
        ACTION="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

if [ -z ${ACTION} ]; then
    infomsg "No action set, default apply will be used."
    ACTION="apply"
elif [ "${ACTION}" != "destroy" ] && [ "${ACTION}" != "apply" ]; then
    errmsg "Invalid action: --action should be one of apply or destroy"
    help
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

cat <<-'EOF'
##########################################################################################################################
 $$$$$$\    $$\     $$\                                            $$$$$$\             $$\                         
$$  __$$\   $$ |    $$ |                                          $$  __$$\            $$ |                        
$$ /  $$ |$$$$$$\   $$$$$$$\   $$$$$$\  $$$$$$$\   $$$$$$\        $$ /  \__| $$$$$$\ $$$$$$\   $$\   $$\  $$$$$$\  
$$$$$$$$ |\_$$  _|  $$  __$$\ $$  __$$\ $$  __$$\  \____$$\       \$$$$$$\  $$  __$$\\_$$  _|  $$ |  $$ |$$  __$$\ 
$$  __$$ |  $$ |    $$ |  $$ |$$$$$$$$ |$$ |  $$ | $$$$$$$ |       \____$$\ $$$$$$$$ | $$ |    $$ |  $$ |$$ /  $$ |
$$ |  $$ |  $$ |$$\ $$ |  $$ |$$   ____|$$ |  $$ |$$  __$$ |      $$\   $$ |$$   ____| $$ |$$\ $$ |  $$ |$$ |  $$ |
$$ |  $$ |  \$$$$  |$$ |  $$ |\$$$$$$$\ $$ |  $$ |\$$$$$$$ |      \$$$$$$  |\$$$$$$$\  \$$$$  |\$$$$$$  |$$$$$$$  |
\__|  \__|   \____/ \__|  \__| \_______|\__|  \__| \_______|       \______/  \_______|  \____/  \______/ $$  ____/ 
                                                                                                         $$ |      
                                                                                                         $$ |      
                                                                                                         \__| 
##########################################################################################################################
EOF

log "Checking for pre-requisites..."
log "Checking for jq..."
check_jq

log "Checking for terraform cli..."
check_terraform_cli

log "Checking for aws cli..."
check_aws_cli

log "Checking for valid aws sso..."
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

ATHENA_SETTINGS="${SCRIPT_PATH}/athena-settings.json"
PLANFILE="build.tfplan"
cat <<-EOF
ACTION=${ACTION}
PROFILE=${PROFILE}
EOF

terraform init -upgrade

if [ "${ACTION}" == "apply" ]; then
    log "Creating cloudtrail, athena database, and named query for cloudtrail table..."
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

    terraform output -json > ${ATHENA_SETTINGS}

    log "Creating the cloudtrail table"
    ATHENA_WORKGROUP_ID=$(jq -r '.athena_workgroup_name.value' ${ATHENA_SETTINGS})
    ATHENA_CREATE_TABLE_QUERY=$(jq -r '.athena_create_table_named_query_id.value' ${ATHENA_SETTINGS})
    NAMED_QUERY=$(aws athena get-named-query --named-query-id ${ATHENA_CREATE_TABLE_QUERY} ${PROFILE})
    QUERY_STRING=$(echo $NAMED_QUERY | jq -r '.NamedQuery.QueryString')
    DATABASE=$(echo $NAMED_QUERY | jq -r '.NamedQuery.Database')
    WORKGROUP=$(echo $NAMED_QUERY | jq -r '.NamedQuery.WorkGroup')

    log "Found named query: ${NAMED_QUERY}"
    log "Executing query..."
    QUERY_EXEC_ID=$(aws athena start-query-execution --query-string="${QUERY_STRING}" --work-group="${WORKGROUP}" --query-execution-context=Database="${DATABASE}" ${PROFILE} | jq -r '.QueryExecutionId')

    while true; do
        QUERY_STATUS=$(aws athena get-query-execution --query-execution-id="${QUERY_EXEC_ID}" ${PROFILE} | jq -r '.QueryExecution.Status.State')
        log "Query status: ${QUERY_STATUS}"
        if [ "${QUERY_STATUS}" == "SUCCEEDED" ] || [ "${QUERY_STATUS}" == "FAILED" ] || [ "${QUERY_STATUS}" == "CANCELLED"]; then
            log "Query complete."
            break;
        else
            log "Query not yet complete. Sleeping..."
            sleep 5
        fi
    done
else
    log "Checking athena settings: ${ATHENA_SETTINGS}..."
    if ! [ -f  ${ATHENA_SETTINGS} ]; then
        errmsg "Athena settings file is not found, unable to continue. Try running apply before destroy."
        exit 1
    else
        log "Athena settings found..."
    fi

    log "Dropping the cloudtrail table"
    ATHENA_WORKGROUP_ID=$(jq -r '.athena_workgroup_name.value' ${ATHENA_SETTINGS})
    ATHENA_DROP_TABLE_QUERY=$(jq -r '.athena_drop_table_named_query_id.value' ${ATHENA_SETTINGS})
    NAMED_QUERY=$(aws athena get-named-query --named-query-id ${ATHENA_DROP_TABLE_QUERY} ${PROFILE})
    QUERY_STRING=$(echo $NAMED_QUERY | jq -r '.NamedQuery.QueryString')
    DATABASE=$(echo $NAMED_QUERY | jq -r '.NamedQuery.Database')
    WORKGROUP=$(echo $NAMED_QUERY | jq -r '.NamedQuery.WorkGroup')

    log "Found named query: ${NAMED_QUERY}"
    log "Executing query..."
    QUERY_EXEC_ID=$(aws athena start-query-execution --query-string="${QUERY_STRING}" --work-group="${WORKGROUP}" --query-execution-context=Database="${DATABASE}" ${PROFILE} | jq -r '.QueryExecutionId')

    while true; do
        QUERY_STATUS=$(aws athena get-query-execution --query-execution-id="${QUERY_EXEC_ID}" ${PROFILE} | jq -r '.QueryExecution.Status.State')
        log "Query status: ${QUERY_STATUS}"
        if [ "${QUERY_STATUS}" == "SUCCEEDED" ] || [ "${QUERY_STATUS}" == "FAILED" ] || [ "${QUERY_STATUS}" == "CANCELLED"]; then
            log "Query complete."
            break;
        else
            log "Query not yet complete. Sleeping..."
            sleep 5
        fi
    done

    # check query status
    if [ "${QUERY_STATUS}" == "SUCCEEDED" ]; then
        log "Drop table complete. Destroying cloudtrail and athena database..."
    else
        errmsg "Query failed to execute: ${QUERY_STATUS}"
        read -p "> Would you to continue with terraform destroy (y/n): " continue_destroy
        case "$continue_destroy" in
            y|Y )
                log "Proceeding with destroy..."
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
log "Athena ${ACTION} setup complete."


