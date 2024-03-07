<a href="https://lacework.com"><img src="https://techally-content.s3-us-west-1.amazonaws.com/public-content/lacework_logo_full.png" width="600"></a>

# terraform-azure-agentless-scanning

[![GitHub release](https://img.shields.io/github/release/lacework/terraform-gcp-agentless-scanning.svg)](https://github.com/lacework/terraform-gcp-agentless-scanning/releases/)
[![Codefresh build status](https://g.codefresh.io/api/badges/pipeline/lacework/terraform-modules%2Ftest-compatibility?type=cf-1&key=eyJhbGciOiJIUzI1NiJ9.NWVmNTAxOGU4Y2FjOGQzYTkxYjg3ZDEx.RJ3DEzWmBXrJX7m38iExJ_ntGv4_Ip8VTa-an8gBwBo)](https://g.codefresh.io/pipelines/edit/new/builds?id=607e25e6728f5a6fba30431b&pipeline=test-compatibility&projects=terraform-modules&projectId=607db54b728f5a5f8930405d)

A Terraform Module to configure the Lacework Agentless Scanner on Azure.

All code contributions made by Lacework customers to this repo are considered ‘Feedback’ under section 4.3 of the Lacework Terms of Service.
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 2.45.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | ~> 3.77.0 |
| <a name="requirement_lacework"></a> [lacework](#requirement\_lacework) | >= 1.18 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azapi"></a> [azapi](#provider\_azapi) | n/a |
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 2.45.0 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | ~> 3.77.0 |
| <a name="provider_lacework"></a> [lacework](#provider\_lacework) | >= 1.18 |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azapi_resource.container_app_job_agentless](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource) | resource |
| [azuread_application.lw](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_service_principal.data_loader](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [azuread_service_principal_password.data_loader](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal_password) | resource |
| [azurerm_container_app_environment.agentless_orchestrate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_app_environment) | resource |
| [azurerm_key_vault.lw_orchestrate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault) | resource |
| [azurerm_key_vault_access_policy.access_for_sidekick](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_access_policy.access_for_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_access_policy) | resource |
| [azurerm_key_vault_secret.lw_orchestrate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/key_vault_secret) | resource |
| [azurerm_log_analytics_workspace.agentless_orchestrate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/log_analytics_workspace) | resource |
| [azurerm_network_security_group.agentless_orchestrate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group) | resource |
| [azurerm_resource_group.scanning_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |
| [azurerm_role_assignment.key_vault_sidekick](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.key_vault_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.orchestrate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.scanner](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.storage_data_loader](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_assignment.storage_sidekick](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_role_definition.agentless_monitored_subscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_role_definition.agentless_scanning_subscription](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_definition) | resource |
| [azurerm_storage_account.scanning](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) | resource |
| [azurerm_storage_container.scanning](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container) | resource |
| [azurerm_user_assigned_identity.sidekick](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/user_assigned_identity) | resource |
| [azurerm_virtual_network.agentless_orchestrate](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network) | resource |
| [lacework_integration_azure_agentless_scanning.lacework_cloud_account](https://registry.terraform.io/providers/lacework/lacework/latest/docs/resources/integration_azure_agentless_scanning) | resource |
| [random_id.uniq](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [azurerm_client_config.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/client_config) | data source |
| [azurerm_resource_group.scanning_rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/resource_group) | data source |
| [azurerm_subscription.current](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscription) | data source |
| [azurerm_subscriptions.available](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/subscriptions) | data source |
| [lacework_metric_module.lwmetrics](https://registry.terraform.io/providers/lacework/lacework/latest/docs/data-sources/metric_module) | data source |
| [lacework_user_profile.current](https://registry.terraform.io/providers/lacework/lacework/latest/docs/data-sources/user_profile) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_blob_container_name"></a> [blob\_container\_name](#input\_blob\_container\_name) | name of the blob container used for storing analysis artifacts. Leave blank to generate one | `string` | `""` | no |
| <a name="input_create_log_analytics_workspace"></a> [create\_log\_analytics\_workspace](#input\_create\_log\_analytics\_workspace) | Creates a log analytics workspace to see container logs. Defaults to false to avoid charging | `bool` | `false` | no |
| <a name="input_custom_network"></a> [custom\_network](#input\_custom\_network) | The name of the custom Azure Virtual Network subnet. Make sure it allows egress traffic on port 443. Leave empty to create a new one. | `string` | `""` | no |
| <a name="input_enable_storage_infrastructure_encryption"></a> [enable\_storage\_infrastructure\_encryption](#input\_enable\_storage\_infrastructure\_encryption) | enable Azure storage account-level infrastructure encryption. Defaults to false | `bool` | `false` | no |
| <a name="input_filter_query_text"></a> [filter\_query\_text](#input\_filter\_query\_text) | The LQL query to constrain the scanning to specific resources. If left blank, Lacework will scan all resources available to the account or organization. For more information, see [Limit Scanned Workloads](https://docs.lacework.net/onboarding/lacework-console-agentless-workload-scanning#aws---limit-scanned-workloads). | `string` | `""` | no |
| <a name="input_global"></a> [global](#input\_global) | Whether we create global resources for this deployment. Defaults to `false` | `bool` | `false` | no |
| <a name="input_global_module_reference"></a> [global\_module\_reference](#input\_global\_module\_reference) | A reference to the global lacework\_azure\_agentless\_scanning module for this account. | <pre>object({<br>    scanning_resource_group_name              = string<br>    key_vault_id                              = string<br>    key_vault_uri                             = string<br>    key_vault_secret_name                     = string<br>    lacework_account                          = string<br>    lacework_domain                           = string<br>    lacework_integration_name                 = string<br>    storage_account_name                      = string<br>    storage_account_id                        = string<br>    blob_container_name                       = string<br>    prefix                                    = string<br>    suffix                                    = string<br>    monitored_subscription_role_definition_id = string<br>    scanning_subscription_role_definition_id  = string<br>    sidekick_principal_id                     = string<br>    sidekick_client_id                        = string<br>    subscriptions_list                        = set(string)<br>  })</pre> | <pre>{<br>  "blob_container_name": "",<br>  "key_vault_id": "",<br>  "key_vault_secret_name": "",<br>  "key_vault_uri": "",<br>  "lacework_account": "",<br>  "lacework_domain": "",<br>  "lacework_integration_name": "",<br>  "monitored_subscription_role_definition_id": "",<br>  "prefix": "",<br>  "scanning_resource_group_name": "",<br>  "scanning_subscription_role_definition_id": "",<br>  "sidekick_client_id": "",<br>  "sidekick_principal_id": "",<br>  "storage_account_id": "",<br>  "storage_account_name": "",<br>  "subscriptions_list": [],<br>  "suffix": ""<br>}</pre> | no |
| <a name="input_image_url"></a> [image\_url](#input\_image\_url) | The container image url for Lacework Agentless Workload Scanning. | `string` | `"public.ecr.aws/p5r4i7k7/sidekick:latest"` | no |
| <a name="input_integration_level"></a> [integration\_level](#input\_integration\_level) | If we are integrating into a subscription or tenant. Valid values are 'SUBSCRIPTION' or 'TENANT' | `string` | n/a | yes |
| <a name="input_key_vault_id"></a> [key\_vault\_id](#input\_key\_vault\_id) | The ID of the Key Vault containing the Lacework Account and Auth Token | `string` | `""` | no |
| <a name="input_lacework_account"></a> [lacework\_account](#input\_lacework\_account) | The name of the Lacework account with which to integrate. | `string` | `""` | no |
| <a name="input_lacework_domain"></a> [lacework\_domain](#input\_lacework\_domain) | The domain of the Lacework account with with to integrate. | `string` | `"lacework.net"` | no |
| <a name="input_lacework_integration_name"></a> [lacework\_integration\_name](#input\_lacework\_integration\_name) | The name of the Lacework cloud account integration. Should only be set in global resource | `string` | `"azure-agentless-scanning"` | no |
| <a name="input_notification_email"></a> [notification\_email](#input\_notification\_email) | Used for receiving notification on key updates such as those to service principal | `string` | `""` | no |
| <a name="input_owner_id"></a> [owner\_id](#input\_owner\_id) | Owner for service account created. Azure recommends having one | `string` | `""` | no |
| <a name="input_prefix"></a> [prefix](#input\_prefix) | A string to be prefixed to the name of all new resources. | `string` | `"lacework"` | no |
| <a name="input_region"></a> [region](#input\_region) | The region where LW scanner is deployed to | `string` | `"westus2"` | no |
| <a name="input_regional"></a> [regional](#input\_regional) | Whether or not to create regional resources. Defaults to `true`. | `bool` | `true` | no |
| <a name="input_scan_containers"></a> [scan\_containers](#input\_scan\_containers) | Whether to includes scanning for containers.  Defaults to `true`. | `bool` | `true` | no |
| <a name="input_scan_frequency_hours"></a> [scan\_frequency\_hours](#input\_scan\_frequency\_hours) | How often in hours the scan will run in hours. Defaults to `24`. | `number` | `24` | no |
| <a name="input_scan_host_vulnerabilities"></a> [scan\_host\_vulnerabilities](#input\_scan\_host\_vulnerabilities) | Whether to includes scanning for host vulnerabilities.  Defaults to `true`. | `bool` | `true` | no |
| <a name="input_scan_multi_volume"></a> [scan\_multi\_volume](#input\_scan\_multi\_volume) | Whether to scan secondary volumes. Defaults to `false`. | `bool` | `false` | no |
| <a name="input_scan_stopped_instances"></a> [scan\_stopped\_instances](#input\_scan\_stopped\_instances) | Whether to scan stopped instances. Defaults to `true`. | `bool` | `true` | no |
| <a name="input_scanning_resource_group_name"></a> [scanning\_resource\_group\_name](#input\_scanning\_resource\_group\_name) | The name of the resource group where LW sidekick is deployed. Leave blank to create a new one | `string` | `""` | no |
| <a name="input_scanning_subscription_id"></a> [scanning\_subscription\_id](#input\_scanning\_subscription\_id) | SubcriptionId where LW Sidekick is deployed. Leave blank to use the current one used by Azure Resource Manager. Show it through `az account show` | `string` | `""` | no |
| <a name="input_storage_account_url"></a> [storage\_account\_url](#input\_storage\_account\_url) | url of the storage account used for storing analysis artifacts. | `string` | `""` | no |
| <a name="input_subscriptions_list"></a> [subscriptions\_list](#input\_subscriptions\_list) | List of subscriptions to be scanned. Prefix a subscription with '-' to exclude it from scanning. Set only for global resource | `set(string)` | `[]` | no |
| <a name="input_suffix"></a> [suffix](#input\_suffix) | A string to be appended to the end of the name of all new resources. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Set of tags which will be added to the resources managed by the module. | `map(string)` | `{}` | no |
| <a name="input_tenant_id"></a> [tenant\_id](#input\_tenant\_id) | TenantId where LW Sidekick is deployed | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agentless_credentials_client_id"></a> [agentless\_credentials\_client\_id](#output\_agentless\_credentials\_client\_id) | Client id of the service principal of Lacework app |
| <a name="output_agentless_credentials_client_secret"></a> [agentless\_credentials\_client\_secret](#output\_agentless\_credentials\_client\_secret) | Client secret of the service principal of Lacework app |
| <a name="output_blob_container_name"></a> [blob\_container\_name](#output\_blob\_container\_name) | The blob container used to store Agentless Workload Scanning data |
| <a name="output_key_vault_id"></a> [key\_vault\_id](#output\_key\_vault\_id) | The ID of the Key Vault that stores the LW credentials |
| <a name="output_key_vault_secret_name"></a> [key\_vault\_secret\_name](#output\_key\_vault\_secret\_name) | The name of the secret stored in key vault. The secret contains LW account authN details |
| <a name="output_key_vault_uri"></a> [key\_vault\_uri](#output\_key\_vault\_uri) | The URI of the key vault that stores LW account details |
| <a name="output_lacework_account"></a> [lacework\_account](#output\_lacework\_account) | Lacework Account Name for Integration. |
| <a name="output_lacework_domain"></a> [lacework\_domain](#output\_lacework\_domain) | Lacework Domain Name for Integration. |
| <a name="output_lacework_integration_name"></a> [lacework\_integration\_name](#output\_lacework\_integration\_name) | The name of the integration. Passed along in global module reference. |
| <a name="output_monitored_subscription_role_definition_id"></a> [monitored\_subscription\_role\_definition\_id](#output\_monitored\_subscription\_role\_definition\_id) | The id of the monitored subscription role definition |
| <a name="output_prefix"></a> [prefix](#output\_prefix) | Prefix used to add uniqueness to resource names. |
| <a name="output_scanning_resource_group_name"></a> [scanning\_resource\_group\_name](#output\_scanning\_resource\_group\_name) | Name of the resource group hosting the scanner |
| <a name="output_scanning_subscription_role_definition_id"></a> [scanning\_subscription\_role\_definition\_id](#output\_scanning\_subscription\_role\_definition\_id) | The id of the scanning subscription role definition |
| <a name="output_sidekick_client_id"></a> [sidekick\_client\_id](#output\_sidekick\_client\_id) | Client id of the managed identity running scanner |
| <a name="output_sidekick_principal_id"></a> [sidekick\_principal\_id](#output\_sidekick\_principal\_id) | The principal id of the user identity used by agentless scanner |
| <a name="output_storage_account_id"></a> [storage\_account\_id](#output\_storage\_account\_id) | The ID of storage account used for scanning |
| <a name="output_storage_account_name"></a> [storage\_account\_name](#output\_storage\_account\_name) | The blob storage account for Agentless Workload Scanning data. |
| <a name="output_subscriptions_list"></a> [subscriptions\_list](#output\_subscriptions\_list) | The subscriptions list in global module reference |
| <a name="output_suffix"></a> [suffix](#output\_suffix) | Suffix used to add uniqueness to resource names. |
<!-- END_TF_DOCS -->