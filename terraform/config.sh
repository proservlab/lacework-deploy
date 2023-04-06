#!/bin/bash

SCRIPTNAME=$(basename $0)
VERSION="1.0.0"

# SCENARIO
SCENARIO=""
CONFIG_FILE=""

# LACEWORK
LACEWORK_PROFILE=""
LACEWORK_ACCOUNT=""

# AWS
ATTACKER_AWS_PROJECT=""
ATTACKER_AWS_LOCATION=""
TARGET_AWS_PROJECT=""
TARGET_AWS_LOCATION=""

# AZURE
ATTACKER_AZURE_SUBSCRIPTION=""
ATTACKER_AZURE_TENANT=""
ATTACKER_AZURE_LOCATION=""
TARGET_AZURE_SUBSCRIPTION=""
TARGET_AZURE_TENANT=""
TARGET_AZURE_LOCATION=""

# GCP
ATTACKER_GCP_PROJECT=""
ATTACKER_GCP_LOCATION=""
TARGET_GCP_PROJECT=""
TARGET_GCP_LOCATION=""
TARGET_GCP_LACEWORK_PROJECT=""
TARGET_GCP_LACEWORK_LOCATION=""

# PROTONVPN
ATTACKER_PROTONVPN_USER=""
ATTACKER_PROTONVPN_PASSWORD=""

# DYNDNS API TOKEN
DYNU_DNS_DOMAIN=""
DYNU_DNS_API_TOKEN=""

help(){
cat <<EOH
usage: $SCRIPTNAME
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

# choose the scenario
function select_scenario {
    # Retrieve list of AWS profiles
    scenarios=$(ls -1 scenarios)

    
    # Ask user to select AWS profile
    infomsg "Select the scenario to configure:"
    PS3="Scenario number: "
    select scenario in $scenarios; do
        if [ -n "$scenario" ]; then
            infomsg "Selected scenario: $scenario"
            SCENARIO=$scenario
            CONFIG_FILE="env_vars/variables-$SCENARIO.tfvars"
            break
        else
            errmsg "Invalid selection. Try again."
        fi
    done
}

function check_file_exists {
  if [ -e "$1" ]; then
    
    read -p "> File '$1' already exists. Do you want to overwrite it? (y/n) " -n 1 -r
    echo    # move to a new line after user input
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      return 0  # User confirmed, return success code
    else
      return 1  # User did not confirm, return error code
    fi
  else
    return 0  # File does not exist, return success code
  fi
}

# Check if aws-cli is installed and install if not
check_aws_cli() {
    if command_exists aws &> /dev/null; then
        infomsg "aws-cli installed."
    else
        infomsg "aws-cli is not installed."
        
        read -p "> Would you like to install it? (y/n): " install_aws_cli
        case "$install_gcloud_cli" in
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

# Check if gcloud is installed and install if not
check_gcloud_cli() {
    if command_exists gcloud &> /dev/null; then
        infomsg "gcloud cli installed."
    else
        infomsg "gcloud cli is not installed."
        
        read -r "> would you like to install it? (y/n): " install_gcloud_cli
        case "$install_gcloud_cli" in
            y|Y )
                if [[ $(uname -s) == "Linux" ]]; then
                    infomsg "installing gcloud for linux..."
                    curl https://sdk.cloud.google.com | bash
                    infomsg -l $SHELL
                elif [[ $(uname -s) == "Darwin" ]]; then
                    infomsg "installing gcloud for mac..."
                    if ! command_exists brew &> /dev/null; then
                        errmsg "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install google-cloud-sdk
                else
                    errmsg "unsupported operating system. Please install gcloud manually."
                    exit 1
                fi
                ;;
            n|N )
                infomsg "gcloud cli will not be installed."
                infomsg "gcloud cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                infomsg "invalid input. gcloud cli will not be installed"
                infomsg "gcloud cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

# Check if Azure CLI is installed and install if necessary
check_azure_cli() {
    if command_exists az &> /dev/null; then
        infomsg "azure cli installed."
    else
        
        read -p "> azure cli is not installed. Would you like to install it? (y/n) " install_azure
        case "$install_azure" in
            y|Y )
                if [[ "$(uname -s)" == "Darwin" ]]; then
                    infomsg "installing azure cli for mac..."
                    if ! command_exists brew &> /dev/null; then
                        errmsg "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install azure-cli
                elif [[ "$(uname -s)" == "Linux" ]]; then
                    infomsg "installing azure cli for linux..."
                    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                else
                    errmsg "unsupported operating system. please install azure cli manually."
                    errmsg "azure cli is required to proceed. Please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                errmsg "azure cli will not be installed."
                errmsg "azure cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                errmsg "invalid input. azure cli will not be installed"
                errmsg "azure cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

# check if lacework cli is installed
check_lacework_cli() {
    if command_exists lacework &> /dev/null; then
        infomsg "lacework cli installed."
    else
        
        read -p "> Lacework CLI is not installed. Would you like to install it? (y/n) " install_lacework
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
                        errmsg "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    # install for macOS using brew
                    brew tap lacework/homebrew-lacework-cli
                    brew install lacework-cli
                else
                    errmsg "unsupported operating system."
                    errmsg "lacework cli is required to proceed. please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                errmsg "lacework cli will not be installed."
                errmsg "lacework cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                errmsg "invalid input. lacework cli will not be installed"
                errmsg "lacework cli is required to proceed. please install it manually."
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
            errmsg "Unknown option: $1"
            exit 1
            ;;
        esac
    done

    if [[ -z $region ]]; then
        region=$(aws configure get region)
    fi

    # Get the number of VPCs deployed in the default region
    vpcs=$(aws ec2 describe-vpcs --region=$region --query 'length(Vpcs[])')

    infomsg "number of VPCs deployed in the $region region: $vpcs"

    # Get the remaining VPC service quota for instances
    vpc_quota=$(aws service-quotas get-service-quota --service-code 'vpc' --quota-code 'L-F678F1CE' --region=$region --query 'Quota.Value' --output json --color off --no-cli-pager | cut -d '.' -f1)

    infomsg "vpc service quota: $vpc_quota"
    
    # Calculate the remaining vpcs
    remaining_vpcs=$((vpc_quota - vpcs))

    infomsg "remaining VPC service quota for instances: $remaining_vpcs"
    
    if [ $remaining_vpcs -lt $min_vpcs ]; then
        errmsg "the remaining deployable vpc count is less than $min_vpcs. increase the vpc quota for this account or choose another account/region to proceed."
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
        infomsg "select the $environment AWS profile:"
        PS3="Profile number: "
        select profile_name in $aws_profiles; do
            if [ -n "$profile_name" ]; then
                infomsg "Selected $environment aws profile: $profile_name"
                break
            else
                errmsg "Invalid selection. Try again."
            fi
        done

        infomsg "Please choose the $environment aws region from the list below:"
        select region in $region_list; do
            if [ -n "$region" ]; then
                infomsg "Selected $environment aws region: $region"
                break
            else
                errmsg "Invalid selection. Try again."
            fi
        done

        if [ "$environment" == "attacker" ]; then
            ATTACKER_AWS_PROFILE=$profile_name
            ATTACKER_AWS_REGION=$region
            aws_check_vpcs -r $ATTACKER_AWS_REGION
        elif [ "$environment" == "target" ]; then
            TARGET_AWS_PROFILE=$profile_name
            TARGET_AWS_REGION=$region
            aws_check_vpcs -r $TARGET_AWS_REGION
        fi;
    done;
}

function select_gcp_project {
    # Set project variable
    projects=$(gcloud projects list --format="value(projectId)")
    
    # iterate through the attack and target environments
    environments="attacker target lacework"
    for environment in $environments; do 
        infomsg "select the $environment gcp project:"
        # Prompt the user to select a project
        PS3="Please select the $environment gcp project: "
        select project_id in $projects; do
            if [[ -n "$project_id" ]]; then
                infomsg "Selected $environment gcp project: $project_id"
                break
            else
                errmsg "Invalid selection. Please try again."
            fi
        done

        infomsg "Fetching valid GCP locations..."
        locations=$(gcloud compute regions list --project=$project_id --format="value(name)")

        # Prompt the user to select a region
        PS3="Please select a locations: "
        select location in $locations; do
            if [[ -n "$location" ]]; then
                infomsg "Selected location: $location"
                break
            else
                errmsg "Invalid selection. Please try again."
            fi
        done
        
        if [ "$environment" == "attacker" ]; then
            ATTACKER_GCP_PROJECT=$project_id
            ATTACKER_GCP_LOCATION=$location
        elif [ "$environment" == "target" ]; then
            TARGET_GCP_PROJECT=$project_id
            TARGET_GCP_LOCATION=$location
        else
            TARGET_GCP_LACEWORK_PROJECT=$project_id
            TARGET_GCP_LACEWORK_LOCATION=$location
        fi;
    done;
}

function select_azure_subscription {
    # Get the current tenant
    local tenant_id=$(az account list --query "[?isDefault].tenantId | [0]" --output tsv)
    
    # iterate through the attack and target environments
    environments="attacker target"
    for environment in $environments; do
        infomsg "select the $environment azure subscription:"
        local options=$(az account list --query "[?tenantId=='$tenant_id'].join('',[id,' (',name, ') isDefault:',to_string(isDefault)])" --output tsv)
        local IFS=$'\n'
        select opt in $options; do
            if [[ -n "$opt" ]]; then
                local subscription_id=$(echo "$opt" | cut -d ' ' -f1)
                infomsg "selected subscription: $subscription_id"
                break
            fi
        done

        infomsg "Retrieving list of Azure regions..."
        regions=($(az account list-locations --query "[].name" --output tsv))
        if [ ${#regions[@]} -eq 0 ]; then
            echo "No valid Azure regions found for subscription $subscription_id."
            return 1
        fi
        PS3="Enter the number of the Azure region you want to use: "
        select region in "${regions[@]}"; do
            if [[ -n $region ]]; then
                echo "You chose the Azure region: $region"
                break
            else
                echo "Invalid selection. Please try again."
            fi
        done

        if [ "$environment" == "attacker" ]; then
            ATTACKER_AZURE_SUBSCRIPTION=$subscription_id
            ATTACKER_AZURE_TENANT=$tenant_id
            ATTACKER_AZURE_LOCATION=$region
        elif [ "$environment" == "target" ]; then
            TARGET_AZURE_SUBSCRIPTION=$subscription_id
            TARGET_AZURE_TENANT=$tenant_id
            TARGET_AZURE_LOCATION=$region
        fi;
    done;

    # Print the selected subscription and organization
    # infomsg "Current tenant: $tenant_id"
}

function select_lacework_profile {
    infomsg "select a lacework profile:"
    # Get the current tenant
    local options=$(lacework configure list | sed 's/>/ /' | awk -v m=2 -v n=3 'NR<=m{next};NR>n+m{print line[NR%n]};{line[NR%n]=$0}' | cut -d " " -f5)
    local IFS=$'\n'
    select opt in $options; do
        if [[ -n "$opt" ]]; then
            LACEWORK_PROFILE=$opt
            infomsg "selected lacework profile: $LACEWORK_PROFILE"
            LACEWORK_ACCOUNT=$(lacework configure show account --profile=$LACEWORK_PROFILE)
            break
        fi
    done
}

function output_aws_config {
    cat <<-EOF 
scenario="$SCENARIO"
deployment="$DEPLOYMENT"
attacker_aws_profile = "$ATTACKER_AWS_PROFILE"
attacker_aws_region = "$ATTACKER_AWS_REGION"
target_aws_profile = "$TARGET_AWS_PROFILE"
target_aws_region = "$TARGET_AWS_REGION"
lacework_profile = "$LACEWORK_PROFILE"
lacework_account_name = "$LACEWORK_ACCOUNT"
lacework_server_url = "https://$LACEWORK_ACCOUNT.lacework.net"
attacker_context_config_protonvpn_user = "$ATTACKER_PROTONVPN_USER"
attacker_context_config_protonvpn_password = "$ATTACKER_PROTONVPN_PASSWORD"
dynu_api_token = "$DYNU_DNS_API_TOKEN"
dynu_dns_domain = "$DYNU_DNS_DOMAIN"
EOF
}

function output_gcp_config {
    cat <<-EOF 
scenario="$SCENARIO"
deployment="$DEPLOYMENT"
target_gcp_project="$TARGET_GCP_PROJECT"
target_gcp_region="$TARGET_GCP_LOCATION"
target_gcp_lacework_project="$TARGET_GCP_LACEWORK_PROJECT"
target_gcp_lacework_region="$TARGET_GCP_LACEWORK_LOCATION"
attacker_gcp_project="$ATTACKER_GCP_PROJECT"
attacker_gcp_region="$ATTACKER_GCP_LOCATION"
lacework_profile = "$LACEWORK_PROFILE"
lacework_account_name = "$LACEWORK_ACCOUNT"
lacework_server_url = "https://$LACEWORK_ACCOUNT.lacework.net"
attacker_context_config_protonvpn_user = "$ATTACKER_PROTONVPN_USER"
attacker_context_config_protonvpn_password = "$ATTACKER_PROTONVPN_PASSWORD"
dynu_api_token = "$DYNU_DNS_API_TOKEN"
dynu_dns_domain = "$DYNU_DNS_DOMAIN"
EOF
}

function output_azure_config {
    cat <<-EOF
scenario="$SCENARIO"
deployment="$DEPLOYMENT"
attacker_azure_subscription = "$ATTACKER_AZURE_SUBSCRIPTION"
attacker_azure_tenant = "$ATTACKER_AZURE_TENANT"
attacker_azure_region = "$ATTACKER_AZURE_LOCATION"
target_azure_subscription = "$TARGET_AZURE_SUBSCRIPTION"
target_azure_tenant = "$TARGET_AZURE_TENANT"
target_azure_region = "$TARGET_AZURE_LOCATION"
lacework_profile = "$LACEWORK_PROFILE"
lacework_account_name = "$LACEWORK_ACCOUNT"
lacework_server_url = "https://$LACEWORK_ACCOUNT.lacework.net"
attacker_context_config_protonvpn_user = "$ATTACKER_PROTONVPN_USER"
attacker_context_config_protonvpn_password = "$ATTACKER_PROTONVPN_PASSWORD"
dynu_api_token = "$DYNU_DNS_API_TOKEN"
dynu_dns_domain = "$DYNU_DNS_DOMAIN"
EOF
}

function config_protonvpn {
    read -p "> do you want to configure protonvpn credentials? (y/n) " protonvpn_config
    case "$protonvpn_config" in
        y|Y ) 
            clear
            read -p "> protonvpn user: " protonvpn_user
            ATTACKER_PROTONVPN_USER=$protonvpn_user
            clear
            read -p "> protonvpn password: " protonvpn_password
            ATTACKER_PROTONVPN_PASSWORD=$protonvpn_password
            ;;
        n|N )
            infomsg "skipping config of protonvpn."
            ;;
        * )
            errmsg "unknown option: $protonvpn_config"
            warnmsg "protonvpn configuration will not be updated."
            ;;
    esac
    
}

function config_dynu {
    read -p "> do you want to configure dynu dns credentials? (y/n) " dynu_config
    case "$dynu_config" in
        y|Y ) 
            clear
            read -p "> dynu dns domain: " dynu_dns_domain
            DYNU_DNS_DOMAIN=$dynu_dns_domain
            clear
            read -p "> dynu dns api token: " dynu_api_token
            DYNU_DNS_API_TOKEN=$dynu_api_token
            ;;
        n|N )
            infomsg "skipping config of dynu dns."
            ;;
        * )
            errmsg "unknown option: $dynu_config"
            warnmsg "dynu dns configuration will not be updated."
            ;;
    esac
}

function select_option {
  PS3="$1"
  shift
  select opt in "$@"; do
    if [[ "$opt" ]]; then
      infomsg "$opt"
      break
    else
      infomsg "Invalid option. Try another one."
    fi
  done
}

clear
# scenario selection
select_scenario

clear
if check_file_exists $CONFIG_FILE; then
    infomsg "Configuration file will be overwritten: $CONFIG_FILE"
    
    # set provider to first segement of workspace name
    PROVIDER=$(echo $SCENARIO | awk -F '-' '{ print $1 }')
    
    # preflight
    check_terraform_cli
    check_lacework_cli

    # deployment id
    clear
    read -p "> provide a unique deployment id or hit enter to use default [00000001]:" deployment_id
    if [ "$deployment_id" == "" ]; then
        DEPLOYMENT="000000001"
    else
        DEPLOYMENT=$deployment_id
    fi
    infomsg "deployment id set: $DEPLOYMENT"

    # lacework selection 
    clear
    select_lacework_profile
    

    # provider preflight
    clear
    if [ "$PROVIDER" == "aws" ]; then
        check_aws_cli
        clear
        select_aws_profile
        clear
        config_protonvpn
        clear
        config_dynu
        clear
        output_aws_config
    elif [ "$PROVIDER" == "gcp" ]; then
        check_gcloud_cli
        clear
        select_gcp_project
        clear
        config_protonvpn
        clear
        config_dynu
        clear
        output_gcp_config
    elif [ "$PROVIDER" == "azure" ]; then
        check_azure_cli
        clear
        select_azure_subscription
        clear
        config_protonvpn
        clear
        config_dynu
        clear
        output_azure_config
    fi
    
    read -p "> do you want to overwrite $CONFIG_FILE with the configuration above? (y/n) " overwrite_config
    case "$overwrite_config" in
        y|Y )
            if [ "$PROVIDER" == "aws" ]; then
                output_aws_config > $CONFIG_FILE
            elif [ "$PROVIDER" == "gcp" ]; then
                output_gcp_config > $CONFIG_FILE
            elif [ "$PROVIDER" == "azure" ]; then
                output_azure_config > $CONFIG_FILE
            fi
            infomsg "configuration file updated."
            infomsg "to apply run: ./build.sh --workspace=$SCENARIO --action=apply"
            ;;
        n|N )
            warnmsg "configuration file will not be updated."
            ;;
        * )
            errmsg "unknown option: $overwrite_config"
            warnmsg "configuration file will not be updated."
            ;;
    esac
else
  errmsg "Existing configuration file found exiting."
  exit 1
fi