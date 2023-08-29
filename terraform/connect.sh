#!/bin/bash

SCRIPTNAME=$(basename $0)
VERSION="1.0.0"


help(){
cat <<EOH
usage: $SCRIPTNAME [-h] [--sso-profile=SSO_PROFILE] [--workspace=WORK] --env=attacker|target

-h                      print this message and exit
--workspace             the scenario to use
--sso-profile           specify an sso login profile
--env                   the environment of the host to connect to
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
    -w=*|--workspace=*)
        WORK="${i#*=}"
        shift # past argument=value
        ;;
    -p=*|--sso-profile=*)
        SSO_PROFILE="--profile=${i#*=}"
        shift # past argument=value
        ;;
    -e=*|--env=*)
        CONNECT_ENV="${i#*=}"
        shift # past argument=value
        ;;
    *)
      # unknown option
      ;;
  esac
done

# setup logging function
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

if [ -z ${CONNECT_ENV} ]; then
    errmsg "Required option not set: --env"
    help
elif [ "${CONNECT_ENV}" != "attacker" ] && [ "${CONNECT_ENV}" != "target" ]; then
    errmsg "Required option incorrect value: --env must be either attacker or target"
    help
fi

if [ -z ${SSO_PROFILE} ]; then
    SSO_PROFILE=""
fi

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

function select_workspace {
    echo "finding all active workspaces - this may take some time..."
    providers=("aws" "gcp" "azure")
    workspaces=()

    for provider in "${providers[@]}"
    do
        # echo "Checking resources for $provider"
        
        # Change directory to the provider's directory
        cd $provider

        # Get the list of workspaces
        workspaces=(${workspaces[@]} $(terraform workspace list | tr -d '*' | grep -v default))

        # Change directory back to the parent directory
        cd ..
    done

    infomsg "Select the workspace to use:"
    PS3="Workspace number: "
    select workspace in "${workspaces[@]}"; do
        if [ -n "$workspace" ]; then
            infomsg "Selected workspace: $workspace"
            WORK=$workspace
            break
        else
            errmsg "Invalid selection. Try again."
        fi
    done
}

# check for required
if [ -z ${WORK} ]; then
    select_workspace
    PROVIDER=$(echo ${WORK} | awk -F '-' '{ print $1 }')
else
    echo $WORK
    PROVIDER=$(echo ${WORK} | awk -F '-' '{ print $1 }')
fi


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

if ! terraform workspace select ${WORK}; then
    errmsg "Unable to locate workspace: ${WORK}"
    cd ..
    select_workspace
    PROVIDER=$(echo ${WORK} | awk -F '-' '{ print $1 }')
    cd $PROVIDER
fi

if [[ "$PROVIDER" == "aws" ]]; then
    json_instances=$(terraform output --json ${CONNECT_ENV}-$PROVIDER-instances)
    instances=($(echo $json_instances | jq -r '.[] | "\(.profile):\(.id):\(.name)"'))
    infomsg "Select the instance to connect to (format: aws_profile:instance_id:instance_name):"
    PS3="Instance number: "
    select instance in "${instances[@]}"; do
        if [ -n "$instance" ]; then
            instArr=(${instance//:/ })
            instance_name=${instArr[2]}       
            instance_id=${instArr[1]}   
            aws_profile=${instArr[0]}   
            echo $instance_name
            echo $instance_id
            echo $aws_profile
            infomsg "Connecting to $instance_name with id $instance_id in aws profile $aws_profile..."
            aws ssm start-session --target=$instance_id --profile=$aws_profile
            break
        else
            errmsg "Invalid selection. Try again."
        fi
    done
elif [[ "$PROVIDER" == "gcp" ]]; then
    json_instances=$(terraform output --json ${CONNECT_ENV}-$PROVIDER-instances)
    instances=($(echo $json_instances | jq -r '.[] | "\(.project_id):\(.name)"'))
    infomsg "Select the instance to connect to (format: gcp_project_id:instance_name):"
    PS3="Instance number: "
    select instance in "${instances[@]}"; do
        if [ -n "$instance" ]; then
            instArr=(${instance//:/ })
            instance_name=${instArr[1]}       
            project_id=${instArr[0]}   
            infomsg "Connecting to $instance_name in project $project_id..."
            gcloud compute ssh $instance_name --project=$project_id --tunnel-through-iap
            break
        else
            errmsg "Invalid selection. Try again."
        fi
    done
elif [[ "$PROVIDER" == "azure" ]]; then
    json_instances=$(terraform output --json  ${CONNECT_ENV}-$PROVIDER-instances)
    instances=($(echo $json_instances | jq -r '.[] | "\(.admin_user):\(.public_ip):\(.name)"'))
    infomsg "Select the instance to connect to (format: admin_user:public_ip:name):"
    PS3="Instance number: "
    select instance in "${instances[@]}"; do
        if [ -n "$instance" ]; then
            instArr=(${instance//:/ })
            instance_name=${instArr[2]}       
            public_ip=${instArr[1]}   
            admin_user=${instArr[0]}   
            ssh_key=$(terraform output --json target_ssh_key | jq -r)
            infomsg "Connecting to $instance_name and public ip $public_ip using ssh key $ssh_key with user $admin_user..."
            ssh -i $ssh_key $admin_user@$public_ip
            break
        else
            errmsg "Invalid selection. Try again."
        fi
    done
fi

