# lacework-deploy

This repo contains example deployment of both infrastructure and lacework components, including security related testing scenarios.

Users are expected to use a terraform `workspace` when deploying the `environment` modules. Example usage:

`./build.sh --workspace=<workspace> --action=apply --stage=all`

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
################################################## Manual execution

################################################## setup
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

**terraform build**
```
################################################## change to terraform directory
cd lacework-deploy/terraform

################################################## initial setup and workspace creation
WORKSPACE=<WORKSPACE>
terraform workspace select ${WORKSPACE} || terraform workspace new ${WORKSPACE}
terraform init -upgrade

# create unique deployment id
terraform plan -var-file=env_vars/variables-<WORKSPACE>.tfvars  -target=module.deployment -out=build.tfplan && terraform apply build.tfplan

# build infrastructure
terraform plan -var-file=env_vars/variables-<WORKSPACE>.tfvars -target=module.target-infrastructure -target=module.attacker-infrastructure -out build.tfplan && terraform apply

# build attacksurface and attacksimulation
terraform plan -var-file=env_vars/variables-<WORKSPACE>.tfvars -out build.tfplan && terraform apply build.tf
plan
```

*Build needs to be done in this order the first time around because each layer requires info from the other. once it's build you can update the json files in scenarios and plan apply that layer and any downstream layers.*

**terraform destory (needs to be done in this order)**
```
# destroy infrastructure attacksurface and attacksimulation
terraform plan -destroy -var-file=env_vars/variables-<WORKSPACE>.tfvars  -out build.tfplan && terraform apply build.tfplan
```

# SSM Access

All AWS instances are setup with SSM management. They can be access via aws-cli ssm commands. This applies to public and private instances as well as cluster nodes.

################################################## List SSM Managed Instances

Output a json list of instance id, state, privateip, publicip and tags for all ssm managed instances
`export ENV=<target|attacker>; aws ssm describe-instance-information --profile=$ENV | jq -r '.InstanceInformationList[] | .InstanceId' | xargs -I '{}' aws ec2 --profile=$ENV describe-instances --instance-id {} | jq -r '.Reservations[] | .Instances[] | { Name:(.Tags|from_entries.Name), InstanceId:.InstanceId, State:.State.Name, PublicIpAddress:.PublicIpAddress, PrivateIpAddress:.PrivateIpAddress }'`

################################################## Connect to Shell on SSM Managed Instance

` aws ssm start-session  --target "<INSTANCE_ID>" --profile=<target|attacker>`

# Metatdata

################################################## AWS Meta-Data

Retrieve public ip address of host on aws from the local machine:
`curl -s "http://169.254.169.254/latest/meta-data/public-ipv4"`

Retrieve instance tags of host on aws from local machine:
`curl -s "http://169.254.169.254/latest/meta-data/tags/instance"`

################################################## GCP Meta-Data

Reteive meta data for compute instance from the local machine:
`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/"`

# Future

Currently security related tests are focused in AWS and are developed to leverage SSM. Future work is required to help ensure these test are idempotent as well as extending this concept to gcp via `osconfig` and azure.