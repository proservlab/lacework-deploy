# lacework-deploy

This repo contains example deployment of both infrastructure and lacework components, including security related testing scenarios.

Users are expected to use a terraform `workspace` when deploying the `environment` modules. Example usage:

`./build.sh --workspace=myworkspace --action=apply`

For each workspace environment, variables for that workspace are read in from the `env_vars` directory. Expected format for environment related vars is `variables-<workspace>.tfvars`.

The environment modules allows for the disabling and enabling of various deployment components, if all components are enabled the following related environment varaibles are required:

```
jira_cloud_api_token = "xxxxxx"
jira_cloud_username = "xxxxxx"
jira_cloud_project_key = "xxxxxx"
jira_cloud_issue_type = "xxxxxx"
jira_cloud_url = "https://xxxxxx.atlassian.net"
slack_token = "https://hooks.slack.com/services/xxxxxx"
proxy_token = "xxxxxx"
lacework_profile = "xxxxxx"
lacework_account_name = "xxxxxx"
lacework_server_url = "https://xxxxxx.lacework.net"
```

# SSM Access

All AWS instances are setup with SSM management. They can be access via aws-cli ssm commands. This applies to public and private instances as well as cluster nodes.

## list ssm managed instances

Output a json list of instance id, state, privateip, publicip and tags for all ssm managed instances
`export ENV=<target|attacker>; aws ssm describe-instance-information --profile=$ENV | jq -r '.InstanceInformationList[] | .InstanceId' | xargs -I '{}' aws ec2 --profile=$ENV describe-instances --instance-id {} | jq -r '.Reservations[] | .Instances[] | { Name:(.Tags|from_entries.Name), InstanceId:.InstanceId, State:.State.Name, PublicIpAddress:.PublicIpAddress, PrivateIpAddress:.PrivateIpAddress }'`

## connect to shell on ssm managed instance

` aws ssm start-session  --target "<INSTANCE_ID>" --profile=<target|attacker>`

# Metatdata

## AWS Meta-Data

Retrieve public ip address of host on aws from the local machine:
`curl -s "http://169.254.169.254/latest/meta-data/public-ipv4"`

Retrieve instance tags of host on aws from local machine:
`curl -s "http://169.254.169.254/latest/meta-data/tags/instance"`

## GCP Meta-Data

Reteive meta data for compute instance from the local machine:
`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/"`

# Future

Currently security related tests are focused in AWS and are developed to leverage ssm. Future work is required to help ensure these test are idempotent as well as extending this concept to gcp via `osconfig` and azure.