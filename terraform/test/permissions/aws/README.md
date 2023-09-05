# Terraform AWS Modules Policy Generator

This directory contains everything required to setup an Athena database and cloudtrail to monitor AWS cloudtrail events. By assigning a user-agent tag, using the `AWS_EXECUTION_ENV` terraform module apply and destroy actions can be traced to determine an IAM policy. Once a policy is generated is then validated by creating a dedicated role with the discovered IAM policy. This role is used by the next execution of terraform apply/destroy to ensure the policy will indeed allow terraform apply/destroy to succeed.

## Getting Started

Before deploying ensure you have the following:
1. a cloud account where your testing will take place
2. the aws cli installed with any associated profile details (i.e. ~/.aws/config). 
3. the user you're using should have `AdministratorAccess` to the cloud account your are using to test
4. the user you're using should be able to assume roles within your test account (this will be required to validate the permissions discovered).

### Athena Database and Cloudtrail

To setup the Athena Database and Cloudtrail we'll use to monitor terraform access requests:
1. run `./setup.sh --profile=<your aws acccount profile> --action=apply`

Once complete an Athena Database and associated Cloudtrail will be created. To remove the Athena Database and Cloudtrail run the following:

1. `./setup.sh --profile=<your aws acccount profile> --action=destroy`

### Event Generation

In order to evaluate the permission required, the initial deployment of the module to be tested should be done with `AdministratorAccess`, ensuring that no permission denied errors occur.

Each of the modules/resources to be tested should be location in a folder with the test name (e.g. `lacework-agentless`). See the `example` directory for an example structure. All of the files in the base directory `main.tf`, `outputs.tf`, `providers.tf`, `variables.tf` and `version.tf` should generally remain untouched. Add your module setup to `custom.tf` where included modules should be setup under the `modules` folder (e.g. `modules/lacework-agentless`).

Once your test is setup, you can generate the events for the intial trace using the following command:

1. `./terrapermes.sh --profile=<your aws profile> --test-name=<your test name (e.g. example, lacework-agentless)> --action=generate`

### Policy Creation

Having generated the intial trace events, they can now be retrieved from the Athena database and a policy can be built. To generate the policy run the following:

1. `./policy_builder.py --profile=<your aws profile> --output=<your test name (e.g. example, lacework-agentless)>.json --test-name=<your test name (e.g. example, lacework-agentless)>`

The result will be an IAM policy file with the name `<your test name (e.g. example, lacework-agentless)>.json`. Although you can use custom names it's easiest to use the same name, as the validation step uses this format by default.

### Validation

With the policy created the final step is to validate the terraform apply/destroy will work with the defined permissions. To validate run the following:

1. `./terrapermes.sh --profile=<your aws profile> --test-name=<your test name> --action=validate`

> **Note**
> Optionally include the `--policy=<path to policy>` if you've created a custom policy name in the previous step.

Validation should result in a successful apply and destroy of the module(s). Provided everything ran successfully the policy file generated can be used in other environments or in deployment planning and design consideration.

If the apply/destroy did no succeed, use the errors provided to determine any addtional required permissions, adding additional permissions to the `<your test name (e.g. example, lacework-agentless)>.json` file and re-running the validate command above.

## Nothing is perfect

Although this process can successfully determine a potential policy there are some cases where the API calls made by terraform, captured in the cloudtrail logs, are not easily mapped one-to-one with permissions. There is some work done to help discover and mitigate these cases. For some of the examples where API calls result in differing permission(s) names see `mappings.json`. Thanks to the now archived [iamfast-python](https://github.com/iann0036/iamfast-python) project for these API to permission mappings.