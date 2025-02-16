# Pre-requisites

## Terraform

The terraform used in this repo required version 1.4 or higher. To install terraform, use the following [guide from hashicorp](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli).

## AWS

For any scenarios that start with  `aws` the following configuration is required:

1. Configure AWS profiles for attacker and target cloud accounts. These can be the same cloud account or different.

## GCP

For any scenarios which start with the `gcp` prefix, the following configuration is required:

1. Have the project name of the project you will deploy your attacker and target infrastructures to. Additionally either use the same project name for Lacework resources or choose another dedicated project.

## Dynu DNS

For any scenarios containing the `dns` term, the following configuration is required:

1. Create a new free dynu dns account on [dynu.com](https://www.dynu.com/)
2. Create a DDNS subdomain, which will be used as the root dns for the host names in the scenario.
3. Create an API Key
4. In either `terraform/env_vars/variables-scenario.tfvars` or `terraform/env_vars/variables.tfavrs` define the both of the following:
* `dynu_dns_domain`
* `dynu_api_key`
