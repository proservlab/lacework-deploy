# lacework-deploy

This repo contains example deployment of both infrastructure and lacework components, including security related testing scenarios.

# Pre-requisites

Before getting started ensure all of the required configuration outlined in the [pre-requisites guide](PREREQS.md) are complete.

# Quick Start

Once the pre-requisites are complete follow the [getting started guide](GETTINGSTARTED.md) to start deploying the pre-configured scenarios.

# Workspace Management

To view a list of _active_ workspaces (i.e. those will deployed resources) the following command can be run:
`./build.sh --workspace-summary`

At this time any workspaces with no deployed resources will be removed.

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

# Future

Currently security related tests are focused in AWS and are developed to leverage SSM. Future work is required to help ensure these test are idempotent.