# lacework-deploy

This repo contains example deployment of both infrastructure and lacework components, including security related testing scenarios.

# Pre-requisites

Before getting started ensure all of the required configuration outlined in the [pre-requisites guide](PREREQS.md) are complete.

# Quick Start

Once the pre-requisites are complete follow the [getting started guide](GETTINGSTARTED.md) to start deploying the pre-configured scenarios.

Use the `./config.sh` command to select a scenario and configure the associated cloud account profile(s) as required. Once configuration is complete for your scenario, use the `./build.sh --workspace=<SCENARIO> --action=plan` to review the terraform plan, followed by `./build.sh --workspace=<SCENARIO> --action=apply`.

> **Note**
> When using multiple sso profiles you may specify `--sso-profile` as an option for `./config.sh` or `./build.sh`.

# Workspace Management

To view a list of _active_ workspaces (i.e. those will deployed resources) the following command can be run:
`./build.sh --workspace-summary`

At this time any workspaces with no deployed resources will be removed.

# Connecting to Deployed Instances

Once configured deployed instances can be connected to using each cloud provider's secure access pattern. To simplify the connection process use the `./connect.sh` cli. For example run `./connect.sh --workspace=<YOUR WORKSPACE> --env=<attacker|target>` to select a valid workspace and environment (i.e. attacker, target. 

> **Note**
> For AWS `aws ssm start-session` is used to tunnel connections from the source workstaion to the deployed instance. In GCP `gcloud compute ssh --tunnel-through-iap` is used to securely tunnel. For Azure an ssh connection is established from the local workspace using the ssh key created by terraform.

# SSM Access

All AWS instances are setup with SSM management. They can be access via aws-cli ssm commands. This applies to public and private instances as well as cluster nodes.

## List SSM Managed Instances

Output a json list of instance id, state, privateip, publicip and tags for all ssm managed instances
`export ENV=<target|attacker>; aws ssm describe-instance-information --profile=$ENV | jq -r '.InstanceInformationList[] | .InstanceId' | xargs -I '{}' aws ec2 --profile=$ENV describe-instances --instance-id {} | jq -r '.Reservations[] | .Instances[] | { Name:(.Tags|from_entries.Name), InstanceId:.InstanceId, State:.State.Name, PublicIpAddress:.PublicIpAddress, PrivateIpAddress:.PrivateIpAddress }'`

## Connect to Shell on SSM Managed Instance

` aws ssm start-session  --target "<INSTANCE_ID>" --profile=<aws profile name>`

## Port forwarding through SSM Managed Instance

`aws ssm start-session --target <INSTANCE_ID> --document-name AWS-StartPortForwardingSessionToRemoteHost --profile=<aws config profile name> --parameters '{"portNumber":["8000"],"localPortNumber":["8000"],"host":["hostname.example.com"]}'`

# OSConfig Access

All GCP instances are enabled for osconfig access. They can be access via the gcloud cli compute ssh command.

## List instances

`gcloud compute instances list --project=<project id>`

## Connect to Shell on OSConfig Managed Instance

`gcloud compute ssh <instance name> --project=<project id>`

## Connect to Shell on OSConfig Managed Using IAP

`gcloud compute ssh <instance name> --project=<project id> --tunnel-through-iap`

# Metatdata

## AWS Meta-Data

Retrieve public ip address of host on aws from the local machine:
`curl -s "http://169.254.169.254/latest/meta-data/public-ipv4"`

Retrieve instance tags of host on aws from local machine:
`curl -s "http://169.254.169.254/latest/meta-data/tags/instance"`

## GCP Meta-Data

Reteive meta data for compute instance from the local machine:
`curl -s "http://metadata.google.internal/computeMetadata/v1/instance/"`

# Tag Catalog

Lacework-deploy uses SSM, OSConfig, and Runbooks on AWS, GCP and Azure respecrtively. When endpoints are tagged with an action a specifc payload is assigned to be run on the target endpoint. The payloads for each of these tags are cataloged here:

* [AWS SSM TAGS](docs/AWS_TAGS.md)
* [GCP OSCONFIG TAGS](docs/GCP_TAGS.md)
* [AZURE RUNBOOK TAGS](docs/AZURE_TAGS.md)

Additionaly tags are using within the terraform for perform public IP address discovery. This allows some jobs to automatically discover the attacker and target ip address.

# Future

Currently security related tests are focused in AWS, GCP and Azure with each developed to leverage SSM, OSConfig and Runbooks respectively. Expanding beyond Linux to include Windows use cases is a goal for future state in additon to providing easier access to tag/action contributions.