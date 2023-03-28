#!/bin/bash

# Function to check if a command is installed
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if aws-cli is installed and install if not
check_aws_cli() {
    if command_exists aws &> /dev/null; then
        echo "aws-cli installed."
    else
        echo "aws-cli is not installed."
        read -rp "Would you like to install it? (y/n): " install_aws_cli
        case "$install_gcloud_cli" in
            y|Y )
                if [[ $(uname -s) == "Linux" ]]; then
                    echo "installing aws-cli for linux..."
                    sudo apt-get update
                    sudo apt-get install -y awscli
                elif [[ $(uname -s) == "Darwin" ]]; then
                    echo "installing aws-cli for mac..."
                    if ! command_exists brew &> /dev/null; then
                        echo "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install awscli
                else
                    echo "Unsupported operating system. Please install aws-cli manually."
                    exit 1
                fi
                ;;
            n|N )
                echo "aws cli will not be installed."
                echo "aws cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                echo "invalid input. aws cli will not be installed"
                echo "aws cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

# Check if gcloud is installed and install if not
check_gcloud_cli() {
    if command_exists gcloud &> /dev/null; then
        echo "gcloud cli installed."
    else
        echo "gcloud cli is not installed."
        read -rp "Would you like to install it? (y/n): " install_gcloud_cli
        case "$install_gcloud_cli" in
            y|Y )
                if [[ $(uname -s) == "Linux" ]]; then
                    echo "installing gcloud for linux..."
                    curl https://sdk.cloud.google.com | bash
                    exec -l $SHELL
                elif [[ $(uname -s) == "Darwin" ]]; then
                    echo "installing gcloud for mac..."
                    if ! command_exists brew &> /dev/null; then
                        echo "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install google-cloud-sdk
                else
                    echo "Unsupported operating system. Please install gcloud manually."
                    exit 1
                fi
                ;;
            n|N )
                echo "gcloud cli will not be installed."
                echo "gcloud cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                echo "invalid input. gcloud cli will not be installed"
                echo "gcloud cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

# Check if Azure CLI is installed and install if necessary
check_azure_cli() {
    if command_exists az &> /dev/null; then
        echo "azure cli installed."
    else
        read -rp "azure cli is not installed. Would you like to install it? (y/n) " install_azure
        case "$install_azure" in
            y|Y )
                if [[ "$(uname -s)" == "Darwin" ]]; then
                    echo "installing azure cli for mac..."
                    if ! command_exists brew &> /dev/null; then
                        echo "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    brew install azure-cli
                elif [[ "$(uname -s)" == "Linux" ]]; then
                    echo "installing azure cli for linux..."
                    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
                else
                    echo "unsupported operating system. please install azure cli manually."
                    echo "azure cli is required to proceed. Please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                echo "azure cli will not be installed."
                echo "azure cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                echo "invalid input. azure cli will not be installed"
                echo "azure cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

# check if lacework cli is installed
check_lacework_cli() {
    if command_exists lacework &> /dev/null; then
        echo "lacework cli installed."
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
                        echo "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    # install for macOS using brew
                    brew tap lacework/homebrew-lacework-cli
                    brew install lacework-cli
                else
                    echo "unsupported operating system."
                    echo "lacework cli is required to proceed. please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                echo "lacework cli will not be installed."
                echo "lacework cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                echo "invalid input. lacework cli will not be installed"
                echo "lacework cli is required to proceed. please install it manually."
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
            echo "terraform version $required_version or higher is required."
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
                            echo "brew is not installed. please install brew first: https://brew.sh/"
                            exit 1
                        fi
                        # install for macOS using brew
                        brew install terraform
                    else
                        echo "unsupported operating system."
                        echo "terraform version $required_version or higher is required. please install it manually."
                        exit 1
                    fi
                    ;;
                n|N )
                    echo "terraform cli will not be upgraded."
                    echo "terraform version $required_version or higher is required. please install it manually."
                    exit 1
                    ;;
                * )
                    echo "terraform cli will not be upgraded."
                    echo "terraform version $required_version or higher is required. please install it manually."
                    exit 1
                    ;;
            esac
        else
            echo "terraform version $installed_version is installed and supported."
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
                        echo "brew is not installed. please install brew first: https://brew.sh/"
                        exit 1
                    fi
                    # install for macOS using brew
                    brew install terraform
                else
                    echo "unsupported operating system."
                    echo "terraform cli is required to proceed. please install it manually."
                    exit 1
                fi
                ;;
            n|N )
                echo "terraform cli will not be installed."
                echo "terraform cli is required to proceed. please install it manually."
                exit 1
                ;;
            * )
                echo "terraform cli is required to proceed. please install it manually."
                exit 1
                ;;
        esac
    fi
}

function aws_check_vpcs {
    local min_vpcs=8
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
            echo "Unknown option: $1"
            exit 1
            ;;
        esac
    done

    if [[ -z $region ]]; then
        region=$(aws configure get region)
    fi

    # Get the number of VPCs deployed in the default region
    vpcs=$(aws ec2 describe-vpcs --region=$region --query 'length(Vpcs[])')

    echo "number of VPCs deployed in the $region region: $vpcs"

    # Get the remaining VPC service quota for instances
    vpc_quota=$(aws service-quotas get-service-quota --service-code 'vpc' --quota-code 'L-F678F1CE' --region=$region --query 'Quota.Value' --output json --color off --no-cli-pager | cut -d '.' -f1)

    echo "vpc service quota: $vpc_quota"
    
    # Calculate the remaining vpcs
    remaining_vpcs=$((vpc_quota - vpcs))

    echo "remaining VPC service quota for instances: $remaining_vpcs"
    
    if [ $remaining_vpcs -lt $min_vpcs ]; then
        echo "the remaining deployable vpc count is less than $min_vpcs. increase the vpc quota for this account or choose another account/region to proceed."
        exit 1
    fi
}

function select_aws_profile {
    # Retrieve list of AWS profiles
    aws_profiles=$(aws configure list-profiles)

    # Ask user to select AWS profile
    echo "Select an AWS profile:"
    PS3="Profile number: "
    select profile_name in $aws_profiles; do
        if [ -n "$profile_name" ]; then
            echo "You selected profile: $profile_name"
            break
        else
            echo "Invalid selection. Try again."
        fi
    done
}

function select_gcp_project {
    # Set project variable
    projects=$(gcloud projects list --format="value(projectId)")

    # Prompt the user to select a project
    PS3="Please select a project: "
    select project_id in $projects; do
        if [[ -n "$project_id" ]]; then
            echo "Selected project: $project_id"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done

    # Set current project and organization
    # gcloud config set project $project

    # Set organization variables
    org_id=$(gcloud projects describe $project_id --format="value(parent.id)")
    org_name=$(gcloud organizations describe $org_id --format="value(displayName)")
    echo "Organization: $org_name ($org_id)"
}

function select_azure_subscription {
    # Get the current tenant
    local tenant_id=$(az account list --query "[?isDefault].tenantId | [0]" --output tsv)

    local options=$(az account list --query "[?tenantId=='$tenant_id'].join('',[id,' (',name, ') isDefault:',to_string(isDefault)])" --output tsv)
    local IFS=$'\n'
    select opt in $options; do
        if [[ -n "$opt" ]]; then
            local subscription_id=$(echo "$opt" | cut -d ' ' -f1)
            echo "selected subscription: $subscription_id"
            break
        fi
    done

    # Print the selected subscription and organization
    echo "Current tenant: $tenant_id"
}

function select_option {
  PS3="$1"
  shift
  select opt in "$@"; do
    if [[ "$opt" ]]; then
      echo "$opt"
      break
    else
      echo "Invalid option. Try another one."
    fi
  done
}


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