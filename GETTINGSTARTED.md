# Getting Started

**Note**: Before proceeding ensure the required configuration outlined in the [pre-requisites](./PREREQS.md) readme are complete.

## Scenarios

The scenarios folder container pre-packaged configuration for a scenario. Each scenario contains configuration for `attacker` and `target` infrastructure, attack surface and simluation. 

* <attacker/target>/infrastructure.json: Contains configuration details for components like compute, ssm software deployment for lacework agent, git and docker, in addition to lacework specific configuration (e.g. cloud audit & config). 

* <attacker/target>/surface.json: Contains configfuration details for components related to attack surface, like opening network ports.

* <shared>/simulation.json: Container combined configuration for attacker and target. Configuration here relates specifically to attack scenarios (e.g. reverse shell initiation and listener).

Execution of the simulation tasks and the software deployment tasks are handled differently in each CSP. For AWS SSM is used, GCP OSConfig and Azure Runbooks. Each of the simulation scenarios will repeat over 30 minutes, with the exception being composite alerts repeating every 2 hours.

## Environment Variables

After choosing a scenario from the scenarios folder, ensure the correlating are configured. 

1. Under the `env_vars` folder there is a `variables-<scenario>.tfvars.example` file.
2. Remove the `.example` suffix and configure the required fields (e.g. <YOUR CONFIG HERE>)

## Plan

To verify the env_vars and scenario execution end-users may choose to `plan` the deployment first. Running the plan for the chosen scenario can be done as follows:

1. From the root of the cloned repo, change directory to the `terraform` folder.
2. Execute the following command:
```
./build.sh --workspace=<scenario folder name> --action=plan
```
3. Validate the output and that no error occur.

## Apply

To apply the scenario configuration, follow the steps below:

1. From the root of the cloned repo, change directory to the `terraform` folder.
2. Execute the following command:
```
./build.sh --workspace=<scenario folder name> --action=apply
```

## Destroy

To apply the scenario configuration, follow the steps below:

1. From the root of the cloned repo, change directory to the `terraform` folder.
2. Execute the following command:
```
./build.sh --workspace=<scenario folder name> --action=destroy
```

## Examples

### aws-simple scenario

1. Ensure your AWS and Terraform pre-requisites are installed and configured. See [pre-requisites](./PREREQS.md).

2. Rename the `terraform/env_vars/aws-simple.tfvars.example` file to `aws-simple.tfvars`. Update the file, replacing each noted area (e.g. <YOUR CONFIG HERE>)

3. From the command line, change directory to the `terraform` folder.

4. Run the following command:
```
./build.sh --workspace=aws-simple --action=apply
```
5. Wait for the execution to complete.
6. Validate in your cloud environment as required.
7. Once complete destroy the environment using the following command:
```
./build.sh --workspace=aws-simple --action=destory
```