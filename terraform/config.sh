#!/bin/bash

# AWS
ATTACKER_AWS_PROJECT=""
ATTACKER_AWS_LOCATION=""
TARGET_AWS_PROJECT=""
TARGET_AWS_LOCATION=""

# AZURE
ATTACKER_AZURE_SUBSCRIPTION=""
ATTACKER_AZURE_LOCATION=""
TARGET_AZURE_SUBSCRIPTION=""
TARGET_AZURE_LOCATION=""

# GCP
ATTACKER_GCP_PROJECT=""
ATTACKER_GCP_LOCATION=""
TARGET_GCP_PROJECT=""
TARGET_GCP_LOCATION=""
TARGET_GCP_LACEWORK_PROJECT=""
TARGET_GCP_LACEWORK_LOCATION=""

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

# Check if aws-cli is installed and install if not
check_aws_cli() {
    if command_exists aws &> /dev/null; then
        log "aws-cli installed."
    else
        log "aws-cli is not installed."
        read -rp "Would you like to install it? (y/n): " install_aws_cli
        case "$install_gcloud_cli" in
            y|Y )
                if [[ $(uname -s) == "Linux" ]]; then
                    log "installing aws-cli for linux..."
                    sudo apt-get update
                    sudo apt-get install -y awscli
                elif [[ $(uname -s) == "Darwin" ]]; then
                    log "installing aws-cli for mac..."
                    if ! command_exists brew &> /dev/null; then
                        log "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install awscli
                else
                    log "Unsupported operating system. Please install aws-cli manually."
                    exit 1
                fi
                ;;
            n|N )
                log "aws cli will not be installed."
                log "aws cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                log "invalid input. aws cli will not be installed"
                log "aws cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

# Check if gcloud is installed and install if not
check_gcloud_cli() {
    if command_exists gcloud &> /dev/null; then
        log "gcloud cli installed."
    else
        log "gcloud cli is not installed."
        read -rp "Would you like to install it? (y/n): " install_gcloud_cli
        case "$install_gcloud_cli" in
            y|Y )
                if [[ $(uname -s) == "Linux" ]]; then
                    log "installing gcloud for linux..."
                    curl https://sdk.cloud.google.com | bash
                    log -l $SHELL
                elif [[ $(uname -s) == "Darwin" ]]; then
                    log "installing gcloud for mac..."
                    if ! command_exists brew &> /dev/null; then
                        echo "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install google-cloud-sdk
                else
                    log "Unsupported operating system. Please install gcloud manually."
                    exit 1
                fi
                ;;
            n|N )
                log "gcloud cli will not be installed."
                log "gcloud cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                log "invalid input. gcloud cli will not be installed"
                log "gcloud cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

# Check if Azure CLI is installed and install if necessary
check_azure_cli() {
    if command_exists az &> /dev/null; then
        log "azure cli installed."
    else
        read -rp "azure cli is not installed. Would you like to install it? (y/n) " install_azure
        case "$install_azure" in
            y|Y )
                if [[ "$(uname -s)" == "Darwin" ]]; then
                    log "installing azure cli for mac..."
                    if ! command_exists brew &> /dev/null; then
                        log "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install azure-cli
                elif [[ "$(uname -s)" == "Linux" ]]; then
                    log "installing azure cli for linux..."
                    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                else
                    log "unsupported operating system. please install azure cli manually."
                    log "azure cli is required to proceed. Please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                log "azure cli will not be installed."
                log "azure cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                log "invalid input. azure cli will not be installed"
                log "azure cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

# check if lacework cli is installed
check_lacework_cli() {
    if command_exists lacework &> /dev/null; then
        log "lacework cli installed."
    else
        read -p "Lacework CLI is not installed. Would you like to install it? (y/n) " install_lacework
        case "$install_lacework" in
            y|Y )
                # check if on Linux or macOS
                if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                    # install for Linux
                    curl https://raw.githubusercontent.com/lacework/go-sdk/main/cli/install.sh | bash
                elif [[ "$OSTYPE" == "darwin"* ]]; then
                    # check if brew is installed
                    if ! command_exists brew &> /dev/null
                    then
                        log "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    # install for macOS using brew
                    brew tap lacework/homebrew-lacework-cli
                    brew install lacework-cli
                else
                    log "unsupported operating system."
                    log "lacework cli is required to proceed. please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                log "lacework cli will not be installed."
                log "lacework cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                log "invalid input. lacework cli will not be installed"
                log "lacework cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

check_terraform_cli() {
    if command_exists terraform &> /dev/null; then
        installed_version=$(terraform version | head -n1 | grep -oP 'v\d+\.\d+\.\d+')
        required_version="v1.4.0"
        if [[ "$(printf '%s\n' "$required_version" "$installed_version" | sort -V | head -n1)" != "$required_version" ]]; then
            log "terraform version $required_version or higher is required."
            read -p "do you want to upgrade the terraform cli version to 1.4.2? (y/n) " upgrade_terraform_cli
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
                            log "brew is not installed. please install brew first: https://brew.sh/"
                            exit 1
                        fi
                        # install for macOS using brew
                        brew install terraform
                    else
                        log "unsupported operating system."
                        log "terraform version $required_version or higher is required. please install it manually."
                        exit 1
                    fi
                    ;;
                n|N )
                    log "terraform cli will not be upgraded."
                    log "terraform version $required_version or higher is required. please install it manually."
                    exit 1
                    ;;
                * )
                    log "terraform cli will not be upgraded."
                    log "terraform version $required_version or higher is required. please install it manually."
                    exit 1
                    ;;
            esac
        else
            log "terraform version $installed_version is installed and supported."
        fi
    else
        read -p "terraform cli is not installed. do you want to install it? (y/n) " install_terraform_cli
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
                        log "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    # install for macOS using brew
                    brew install terraform
                else
                    log "unsupported operating system."
                    log "terraform cli is required to proceed. please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                log "terraform cli will not be installed."
                log "terraform cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                log "terraform cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

function aws_check_vpcs {
    local min_vpcs=2
    while [[ $# -gt 0 ]]
    do
        key="$1"
        case $key in
            -r|--region)
            region="$2"
            shift # past argument
            shift # past value
            ;;
            *)
            log "Unknown option: $1"
            exit 1
            ;;
        esac
    done

    if [[ -z $region ]]; then
        region=$(aws configure get region)
    fi

    # Get the number of VPCs deployed in the default region
    vpcs=$(aws ec2 describe-vpcs --region=$region --query 'length(Vpcs[])')

    log "number of VPCs deployed in the $region region: $vpcs"

    # Get the remaining VPC service quota for instances
    vpc_quota=$(aws service-quotas get-service-quota --service-code 'vpc' --quota-code 'L-F678F1CE' --region=$region --query 'Quota.Value' --output json --color off --no-cli-pager | cut -d '.' -f1)

    log "vpc service quota: $vpc_quota"
    
    # Calculate the remaining vpcs
    remaining_vpcs=$((vpc_quota - vpcs))

    log "remaining VPC service quota for instances: $remaining_vpcs"
    
    if [ $remaining_vpcs -lt $min_vpcs ]; then
        log "the remaining deployable vpc count is less than $min_vpcs. increase the vpc quota for this account or choose another account/region to proceed."
        exit 1
    fi
}

function select_aws_profile {
    # Retrieve list of AWS profiles
    aws_profiles=$(aws configure list-profiles)
    region_list=$(aws ec2 describe-regions --query 'Regions[*].RegionName' --output text)

    # iterate through the attack and target environments
    environments="attacker target"
    for environment in $environments; do 
        # Ask user to select AWS profile
        log "Select the $environment AWS profile:"
        PS3="Profile number: "
        select profile_name in $aws_profiles; do
            if [ -n "$profile_name" ]; then
                log "Selected $environment aws profile: $profile_name"
                break
            else
                log "Invalid selection. Try again."
            fi
        done

        log "Please choose the $environment aws region from the list below:"
        select region in $region_list; do
            if [ -n "$region" ]; then
                log "Selected $environment aws region: $region"
                break
            else
                log "Invalid selection. Try again."
            fi
        done

        if [ "$environment" == "attacker" ]; then
            ATTACKER_AWS_PROFILE=$profile_name
            ATTACKER_AWS_REGION=$region
        elif [ "$environment" == "target" ]; then
            TARGET_AWS_PROFILE=$profile_name
            TARGET_AWS_REGION=$region
        fi;
    done;
}

function select_gcp_project {
    # Set project variable
    projects=$(gcloud projects list --format="value(projectId)")
    
    # iterate through the attack and target environments
    environments="attacker target lacework"
    for environment in $environments; do 
        # Prompt the user to select a project
        PS3="Please select the $environment gcp project: "
        select project_id in $projects; do
            if [[ -n "$project_id" ]]; then
                log "Selected $environment gcp project: $project_id"
                break
            else
                log "Invalid selection. Please try again."
            fi
        done

        log "Fetching valid GCP locations..."
        locations=$(gcloud compute regions list --project=$project_id --format="value(name)")

        # Prompt the user to select a region
        PS3="Please select a locations: "
        select location in $locations; do
            if [[ -n "$location" ]]; then
                log "Selected location: $location"
                break
            else
                log "Invalid selection. Please try again."
            fi
        done
        
        if [ "$environment" == "attacker" ]; then
            ATTACKER_GCP_PROJECT=$project_id
            ATTACKER_GCP_LOCATION=$location
        elif [ "$environment" == "target" ]; then
            TARGET_GCP_PROJECT=$project_id
            TARGET_GCP_LOCATION=$location
        else
            LACEWORK_GCP_PROJECT=$project_id
            LACEWORK_GCP_LOCATION=$location
        fi;
    done;
}

function select_azure_subscription {
    # Get the current tenant
    local tenant_id=$(az account list --query "[?isDefault].tenantId | [0]" --output tsv)

    local options=$(az account list --query "[?tenantId=='$tenant_id'].join('',[id,' (',name, ') isDefault:',to_string(isDefault)])" --output tsv)
    local IFS=$'\n'
    select opt in $options; do
        if [[ -n "$opt" ]]; then
            local subscription_id=$(echo "$opt" | cut -d ' ' -f1)
            log "selected subscription: $subscription_id"
            break
        fi
    done

    # Print the selected subscription and organization
    log "Current tenant: $tenant_id"
}

function select_option {
  PS3="$1"
  shift
  select opt in "$@"; do
    if [[ "$opt" ]]; then
      log "$opt"
      break
    else
      log "Invalid option. Try another one."
    fi
  done
}

# select_gcp_project 
# echo "ATTACKER_GCP_PROJECT: $ATTACKER_GCP_PROJECT"
# echo "ATTACKER_GCP_LOCATION: $ATTACKER_GCP_LOCATION"
# echo "TARGET_GCP_PROJECT: $TARGET_GCP_PROJECT"
# echo "TARGET_GCP_LOCATION: $TARGET_GCP_LOCATION"
# echo "LACEWORK_GCP_PROJECT: $LACEWORK_GCP_PROJECT"
# echo "LACEWORK_GCP_LOCATION: $LACEWORK_GCP_LOCATION"

select_aws_profile
echo "ATTACKER_AWS_PROFILE=$ATTACKER_AWS_PROFILE"
echo "ATTACKER_AWS_REGION=$ATTACKER_AWS_REGION"
echo "TARGET_AWS_PROFILE=$TARGET_AWS_PROFILE"
echo "TARGET_AWS_REGION=$TARGET_AWS_REGION"

# select_aws_region
# aws_check_vpcs
# check_terraform_cli
# check_aws_cli
# check_gcloud_cli
# check_azure_cli

# select_aws_profile
# select_gcp_project
# select_azure_subscription

# # Prompt user for values
# read -p "Enter environment: " environment
# read -p "Enter deployment: " deployment

# # Prompt user to choose boolean values
# echo "Select a value for trust_security_group:"
# PS3="Choice: "
# select trust_security_group in "true" "false"; do
#     case $trust_security_group in
#         true|false)
#             break
#             ;;
#         *)
#             echo "Invalid selection. Try again."
#             ;;
#     esac
# done

# echo "Select a value for disable_all:"
# PS3="Choice: "
# select disable_all in "true" "false"; do
#     case $disable_all in
#         true|false)
#             break
#             ;;
#         *)
#             echo "Invalid selection. Try again."
#             ;;
#     esac
# done

# echo "Select a value for enable_all:"
# PS3="Choice: "
# select enable_all in "true" "false"; do
#     case $enable_all in
#         true|false)
#             break
#             ;;
#         *)
#             echo "Invalid selection. Try again."
#             ;;
#     esac
# done