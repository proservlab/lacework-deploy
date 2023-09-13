<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4.0 |
| <a name="requirement_utils"></a> [utils](#requirement\_utils) | 1.6.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_null"></a> [null](#provider\_null) | 3.2.1 |
| <a name="provider_time"></a> [time](#provider\_time) | 0.9.1 |
| <a name="provider_utils"></a> [utils](#provider\_utils) | 1.6.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_attacker-attacksimulation-context"></a> [attacker-attacksimulation-context](#module\_attacker-attacksimulation-context) | ./modules/context/attack/simulate | n/a |
| <a name="module_attacker-attacksurface-context"></a> [attacker-attacksurface-context](#module\_attacker-attacksurface-context) | ./modules/context/attack/surface | n/a |
| <a name="module_attacker-azure-attacksimulation"></a> [attacker-azure-attacksimulation](#module\_attacker-azure-attacksimulation) | ./modules/attack/simulate/azure | n/a |
| <a name="module_attacker-azure-attacksurface"></a> [attacker-azure-attacksurface](#module\_attacker-azure-attacksurface) | ./modules/attack/surface/azure | n/a |
| <a name="module_attacker-azure-infrastructure"></a> [attacker-azure-infrastructure](#module\_attacker-azure-infrastructure) | ./modules/infrastructure/azure | n/a |
| <a name="module_attacker-infrastructure-context"></a> [attacker-infrastructure-context](#module\_attacker-infrastructure-context) | ./modules/context/infrastructure | n/a |
| <a name="module_attacker-lacework-platform-infrastructure"></a> [attacker-lacework-platform-infrastructure](#module\_attacker-lacework-platform-infrastructure) | ./modules/infrastructure/lacework/platform | n/a |
| <a name="module_default-attacksimulation-context"></a> [default-attacksimulation-context](#module\_default-attacksimulation-context) | ../modules/context/attack/simulate | n/a |
| <a name="module_default-attacksurface-context"></a> [default-attacksurface-context](#module\_default-attacksurface-context) | ../modules/context/attack/surface | n/a |
| <a name="module_default-infrastructure-context"></a> [default-infrastructure-context](#module\_default-infrastructure-context) | ../modules/context/infrastructure | n/a |
| <a name="module_deployment"></a> [deployment](#module\_deployment) | ../modules/context/deployment | n/a |
| <a name="module_target-attacksimulation-context"></a> [target-attacksimulation-context](#module\_target-attacksimulation-context) | ./modules/context/attack/simulate | n/a |
| <a name="module_target-attacksurface-context"></a> [target-attacksurface-context](#module\_target-attacksurface-context) | ./modules/context/attack/surface | n/a |
| <a name="module_target-azure-attacksimulation"></a> [target-azure-attacksimulation](#module\_target-azure-attacksimulation) | ./modules/attack/simulate/azure | n/a |
| <a name="module_target-azure-attacksurface"></a> [target-azure-attacksurface](#module\_target-azure-attacksurface) | ./modules/attack/surface/azure | n/a |
| <a name="module_target-azure-infrastructure"></a> [target-azure-infrastructure](#module\_target-azure-infrastructure) | ./modules/infrastructure/azure | n/a |
| <a name="module_target-infrastructure-context"></a> [target-infrastructure-context](#module\_target-infrastructure-context) | ./modules/context/infrastructure | n/a |
| <a name="module_target-lacework-platform-infrastructure"></a> [target-lacework-platform-infrastructure](#module\_target-lacework-platform-infrastructure) | ./modules/infrastructure/lacework/platform | n/a |

## Resources

| Name | Type |
|------|------|
| [null_resource.kubeconfig](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [time_sleep.wait_120_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [utils_deep_merge_json.attacker-attacksimulation-config](https://registry.terraform.io/providers/cloudposse/utils/1.6.0/docs/data-sources/deep_merge_json) | data source |
| [utils_deep_merge_json.attacker-attacksurface-config](https://registry.terraform.io/providers/cloudposse/utils/1.6.0/docs/data-sources/deep_merge_json) | data source |
| [utils_deep_merge_json.attacker-infrastructure-config](https://registry.terraform.io/providers/cloudposse/utils/1.6.0/docs/data-sources/deep_merge_json) | data source |
| [utils_deep_merge_json.target-attacksimulation-config](https://registry.terraform.io/providers/cloudposse/utils/1.6.0/docs/data-sources/deep_merge_json) | data source |
| [utils_deep_merge_json.target-attacksurface-config](https://registry.terraform.io/providers/cloudposse/utils/1.6.0/docs/data-sources/deep_merge_json) | data source |
| [utils_deep_merge_json.target-infrastructure-config](https://registry.terraform.io/providers/cloudposse/utils/1.6.0/docs/data-sources/deep_merge_json) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attacker_aws_profile"></a> [attacker\_aws\_profile](#input\_attacker\_aws\_profile) | attacker aws profile | `string` | `null` | no |
| <a name="input_attacker_aws_region"></a> [attacker\_aws\_region](#input\_attacker\_aws\_region) | attacker aws region | `string` | `"us-east-1"` | no |
| <a name="input_attacker_azure_region"></a> [attacker\_azure\_region](#input\_attacker\_azure\_region) | attacker azure region | `string` | `"West US 2"` | no |
| <a name="input_attacker_azure_subscription"></a> [attacker\_azure\_subscription](#input\_attacker\_azure\_subscription) | attacker azure subscription | `string` | `null` | no |
| <a name="input_attacker_azure_tenant"></a> [attacker\_azure\_tenant](#input\_attacker\_azure\_tenant) | attacker azure tenant | `string` | `null` | no |
| <a name="input_attacker_cluster_name"></a> [attacker\_cluster\_name](#input\_attacker\_cluster\_name) | attacker cluster name | `string` | `"attacker-cluster"` | no |
| <a name="input_attacker_context_cloud_cryptomining_ethermine_wallet"></a> [attacker\_context\_cloud\_cryptomining\_ethermine\_wallet](#input\_attacker\_context\_cloud\_cryptomining\_ethermine\_wallet) | cloud cryptomining ethermine wallet | `string` | `""` | no |
| <a name="input_attacker_context_config_protonvpn_password"></a> [attacker\_context\_config\_protonvpn\_password](#input\_attacker\_context\_config\_protonvpn\_password) | protonvpn password | `string` | `""` | no |
| <a name="input_attacker_context_config_protonvpn_protocol"></a> [attacker\_context\_config\_protonvpn\_protocol](#input\_attacker\_context\_config\_protonvpn\_protocol) | protonvpn protocol | `string` | `"udp"` | no |
| <a name="input_attacker_context_config_protonvpn_server"></a> [attacker\_context\_config\_protonvpn\_server](#input\_attacker\_context\_config\_protonvpn\_server) | protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals | `string` | `"RANDOM"` | no |
| <a name="input_attacker_context_config_protonvpn_tier"></a> [attacker\_context\_config\_protonvpn\_tier](#input\_attacker\_context\_config\_protonvpn\_tier) | protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary) | `number` | `0` | no |
| <a name="input_attacker_context_config_protonvpn_user"></a> [attacker\_context\_config\_protonvpn\_user](#input\_attacker\_context\_config\_protonvpn\_user) | protonvpn user | `string` | `""` | no |
| <a name="input_attacker_context_host_cryptomining_minergate_user"></a> [attacker\_context\_host\_cryptomining\_minergate\_user](#input\_attacker\_context\_host\_cryptomining\_minergate\_user) | host cryptomining user | `string` | `""` | no |
| <a name="input_attacker_context_host_cryptomining_nicehash_user"></a> [attacker\_context\_host\_cryptomining\_nicehash\_user](#input\_attacker\_context\_host\_cryptomining\_nicehash\_user) | host cryptomining user | `string` | `""` | no |
| <a name="input_attacker_gcp_lacework_project"></a> [attacker\_gcp\_lacework\_project](#input\_attacker\_gcp\_lacework\_project) | attacker gcp lacework profile | `string` | `null` | no |
| <a name="input_attacker_gcp_lacework_region"></a> [attacker\_gcp\_lacework\_region](#input\_attacker\_gcp\_lacework\_region) | attacker gcp lacework region | `string` | `"us-central1"` | no |
| <a name="input_attacker_gcp_project"></a> [attacker\_gcp\_project](#input\_attacker\_gcp\_project) | attacker gcp project | `string` | `null` | no |
| <a name="input_attacker_gcp_region"></a> [attacker\_gcp\_region](#input\_attacker\_gcp\_region) | attacker gcp region | `string` | `"us-central1"` | no |
| <a name="input_deployment"></a> [deployment](#input\_deployment) | Unique deployment id | `string` | `"00000001"` | no |
| <a name="input_dynu_api_key"></a> [dynu\_api\_token](#input\_dynu\_api\_token) | dns hostname provisioning api key | `string` | `""` | no |
| <a name="input_dynu_dns_domain"></a> [dynu\_dns\_domain](#input\_dynu\_dns\_domain) | n/a | `string` | `""` | no |
| <a name="input_jira_cloud_api_token"></a> [jira\_cloud\_api\_token](#input\_jira\_cloud\_api\_token) | jira api token | `string` | `""` | no |
| <a name="input_jira_cloud_issue_type"></a> [jira\_cloud\_issue\_type](#input\_jira\_cloud\_issue\_type) | jira issue type | `string` | `""` | no |
| <a name="input_jira_cloud_project_key"></a> [jira\_cloud\_project\_key](#input\_jira\_cloud\_project\_key) | jira cloud project key | `string` | `""` | no |
| <a name="input_jira_cloud_url"></a> [jira\_cloud\_url](#input\_jira\_cloud\_url) | jira cloud url | `string` | `""` | no |
| <a name="input_jira_cloud_username"></a> [jira\_cloud\_username](#input\_jira\_cloud\_username) | jira username | `string` | `""` | no |
| <a name="input_lacework_account_name"></a> [lacework\_account\_name](#input\_lacework\_account\_name) | lacework account name | `string` | n/a | yes |
| <a name="input_lacework_agent_access_token"></a> [lacework\_agent\_access\_token](#input\_lacework\_agent\_access\_token) | lacework agent token | `string` | `null` | no |
| <a name="input_lacework_profile"></a> [lacework\_profile](#input\_lacework\_profile) | lacework account profile name | `string` | n/a | yes |
| <a name="input_lacework_proxy_token"></a> [lacework\_proxy\_token](#input\_lacework\_proxy\_token) | lacework proxy token used by the admissions controller | `string` | `null` | no |
| <a name="input_lacework_server_url"></a> [lacework\_server\_url](#input\_lacework\_server\_url) | lacework server url | `string` | `"https://agent.lacework.net"` | no |
| <a name="input_region"></a> [region](#input\_region) | default aws region | `string` | `"us-east-1"` | no |
| <a name="input_scenario"></a> [scenario](#input\_scenario) | Scenario directory name | `string` | `"simple"` | no |
| <a name="input_slack_token"></a> [slack\_token](#input\_slack\_token) | slack webhook for critical alerts | `string` | `"false"` | no |
| <a name="input_target_aws_profile"></a> [target\_aws\_profile](#input\_target\_aws\_profile) | target aws profile | `string` | `null` | no |
| <a name="input_target_aws_region"></a> [target\_aws\_region](#input\_target\_aws\_region) | target aws region | `string` | `"us-east-1"` | no |
| <a name="input_target_azure_region"></a> [target\_azure\_region](#input\_target\_azure\_region) | target azure region | `string` | `"West US 2"` | no |
| <a name="input_target_azure_subscription"></a> [target\_azure\_subscription](#input\_target\_azure\_subscription) | target azure subscription | `string` | `null` | no |
| <a name="input_target_azure_tenant"></a> [target\_azure\_tenant](#input\_target\_azure\_tenant) | target azure tenant | `string` | `null` | no |
| <a name="input_target_cluster_name"></a> [target\_cluster\_name](#input\_target\_cluster\_name) | target cluster name | `string` | `"target-cluster"` | no |
| <a name="input_target_gcp_lacework_project"></a> [target\_gcp\_lacework\_project](#input\_target\_gcp\_lacework\_project) | target gcp lacework profile | `string` | `null` | no |
| <a name="input_target_gcp_lacework_region"></a> [target\_gcp\_lacework\_region](#input\_target\_gcp\_lacework\_region) | target gcp lacework region | `string` | `"us-central1"` | no |
| <a name="input_target_gcp_project"></a> [target\_gcp\_project](#input\_target\_gcp\_project) | target gcp profile | `string` | `null` | no |
| <a name="input_target_gcp_region"></a> [target\_gcp\_region](#input\_target\_gcp\_region) | target gcp region | `string` | `"us-central1"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_instances"></a> [instances](#output\_instances) | n/a |
| <a name="output_ssh_key"></a> [ssh\_key](#output\_ssh\_key) | n/a |
<!-- END_TF_DOCS -->