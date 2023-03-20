# lacework-deploy

This repo contains example deployment of both infrastructure and lacework components, including security related testing scenarios.

Example usage:

`./build.sh --workspace=<workspace> --action=apply`

For each workspace environment, variables for that workspace are read in from the `env_vars` directory. Expected format for environment related vars is `variables-<workspace>.tfvars`.

The environment modules allows for the disabling and enabling of various deployment components, if all components are enabled the following related environment varaibles are required:

```
scenario="simple"
attacker_aws_profile = "xxxxxx"
attacker_gcp_project = "xxxxxx"
target_aws_profile = "xxxxxx"
target_gcp_project = "xxxxxx"
target_gcp_lacework_project = "xxxxxx"
lacework_profile = "xxxxxx"
lacework_account_name = "xxxxxx"
lacework_server_url = "https://xxxxxx.lacework.net"
jira_cloud_api_token = "xxxxxx"
jira_cloud_username = "xxxxxx"
jira_cloud_project_key = "xxxxxx"
jira_cloud_issue_type = "xxxxxx"
jira_cloud_url = "https://xxxxxx.atlassian.net"
slack_token = "https://hooks.slack.com/services/xxxxxx"
lacework_profile = "xxxxxx"
lacework_account_name = "xxxxxx"
lacework_server_url = "https://xxxxxx.lacework.net"
```

Define the environment using json configuration files in the scenarios directory.
## Manual execution

## setup
1. download install or upgrade to terraform 1.3.7. download zip files can be found here: https://releases.hashicorp.com/terraform/1.3.7/
2. create two aws profiles (attacker and target) they can be the same cloud account just make sure the names are present
3. create a name lacework profile `lacework configure -j <APIKEY> --profile=<LACEWORK_PROFILENAME>
4. create a new file variables-<WORKSPACE_NAME>.tfvars in terraform/env_vars/
5. add the following content:
```
attacker_aws_profile = "<ATTACKER AWS PROFILENAME>"
target_aws_profile = "<TARGET AWS PROFILENAME>"
lacework_profile = "<LACEWORK PROFILENAME>"
lacework_account_name = "<LACEWORK ACCOUNT NAME (e.g. mytenant)>"
lacework_server_url = "<LACEWORK URL (e.g. https://mytenant.lacework.net)"
```

# SSM Access

All AWS instances are setup with SSM management. They can be access via aws-cli ssm commands. This applies to public and private instances as well as cluster nodes.

## List SSM Managed Instances

Output a json list of instance id, state, privateip, publicip and tags for all ssm managed instances
`export ENV=<target|attacker>; aws ssm describe-instance-information --profile=$ENV | jq -r '.InstanceInformationList[] | .InstanceId' | xargs -I '{}' aws ec2 --profile=$ENV describe-instances --instance-id {} | jq -r '.Reservations[] | .Instances[] | { Name:(.Tags|from_entries.Name), InstanceId:.InstanceId, State:.State.Name, PublicIpAddress:.PublicIpAddress, PrivateIpAddress:.PrivateIpAddress }'`

## Connect to Shell on SSM Managed Instance

` aws ssm start-session  --target "<INSTANCE_ID>" --profile=<target|attacker>`

# OSConfig Access

All GCP instances are enabled for osconfig access. They can be access via the gcloud cli compute ssh command.

## List instances

`gcloud compute instances list`

## Connect to Shell on OSConfig Managed Instance

`gcloud compute ssh <instance name>`

# Metatdata

## AWS Meta-Data

Retrieve public ip address of host on aws from the local machine:
`curl -s "http://169.254.169.254/latest/meta-data/public-ipv4"`

Retrieve instance tags of host on aws from local machine:
`curl -s "http://169.254.169.254/latest/meta-data/tags/instance"`

## GCP Meta-Data

Reteive meta data for compute instance from the local machine:
`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/"`

# Proton VPN Credentials

Note that when configuring the `attacker_context_config_protonvpn_user` and `attacker_context_config_protonvpn_password` these values **should NOT** be your protonvpn login username and password but the OpenVPN/IKEv2 credentials. Details on obtaining these credentials are found under the `Finding your OpenVPN / IKEv2 credentials` section [here](https://protonvpn.com/support/vpn-login/#:~:text=Note%3A%20For%20existing%20Proton%20Mail,the%20top%20right%20hand%20corner.)

# Future

Currently security related tests are focused in AWS and are developed to leverage SSM. Future work is required to help ensure these test are idempotent as well as extending this concept to gcp via `osconfig` and azure.