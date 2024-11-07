<a href="https://lacework.com"><img src="https://techally-content.s3-us-west-1.amazonaws.com/public-content/lacework_logo_full.png" width="600"></a>

# terraform-azure-ad-application

[![GitHub release](https://img.shields.io/github/release/lacework/terraform-azure-ad-application.svg)](https://github.com/lacework/terraform-azure-ad-application/releases/)
[![Codefresh build status](https://g.codefresh.io/api/badges/pipeline/lacework/terraform-modules%2Ftest-compatibility?type=cf-1&key=eyJhbGciOiJIUzI1NiJ9.NWVmNTAxOGU4Y2FjOGQzYTkxYjg3ZDEx.RJ3DEzWmBXrJX7m38iExJ_ntGv4_Ip8VTa-an8gBwBo)](https://g.codefresh.io/pipelines/edit/new/builds?id=607e25e6728f5a6fba30431b&pipeline=test-compatibility&projects=terraform-modules&projectId=607db54b728f5a5f8930405d)

Terraform module that creates an Azure Active Directory Application to provide Lacework read-only access to Azure Subscriptions and Tenants.
Lacework logins to Azure using a service principal (an App Registration) with Directory.Read.All on [MS Graph API](https://docs.microsoft.com/en-us/graph/api/user-list?view=graph-rest-1.0&tabs=http#permissions) which can also be achieved using a [Directory Reader role on Azure AD](https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference#directory-readers)
<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.14 |
| <a name="requirement_azuread"></a> [azuread](#requirement\_azuread) | ~> 3.0 |
| <a name="requirement_lacework"></a> [lacework](#requirement\_lacework) | ~> 2.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azuread"></a> [azuread](#provider\_azuread) | ~> 3.0 |
| <a name="provider_lacework"></a> [lacework](#provider\_lacework) | ~> 2.0 |
| <a name="provider_time"></a> [time](#provider\_time) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azuread_application.lacework](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application) | resource |
| [azuread_application_password.client_secret](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/application_password) | resource |
| [azuread_directory_role.dir_reader](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/directory_role) | resource |
| [azuread_directory_role_assignment.lacework_dir_reader](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/directory_role_assignment) | resource |
| [azuread_service_principal.lacework](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/resources/service_principal) | resource |
| [time_sleep.wait_60_seconds](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep) | resource |
| [azuread_client_config.current](https://registry.terraform.io/providers/hashicorp/azuread/latest/docs/data-sources/client_config) | data source |
| [lacework_metric_module.lwmetrics](https://registry.terraform.io/providers/lacework/lacework/latest/docs/data-sources/metric_module) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_application_name"></a> [application\_name](#input\_application\_name) | The name of the Azure Active Directory Application | `string` | `"lacework_security_audit"` | no |
| <a name="input_application_owners"></a> [application\_owners](#input\_application\_owners) | The owners of the Azure Active Directory Application. If empty, current user will be owner | `list(string)` | `[]` | no |
| <a name="input_create"></a> [create](#input\_create) | Set to `false` to prevent the module from creating any resources | `bool` | `true` | no |
| <a name="input_enable_directory_reader"></a> [enable\_directory\_reader](#input\_enable\_directory\_reader) | Enable Directory Reader role for this principal. This will allow Lacework to read Users/Groups/Principals from MS Graph API | `bool` | `true` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_application_id"></a> [application\_id](#output\_application\_id) | The Lacework AD Client id |
| <a name="output_application_password"></a> [application\_password](#output\_application\_password) | The Lacework AD Application password |
| <a name="output_created"></a> [created](#output\_created) | Was the Active Directory Application created |
| <a name="output_enable_directory_reader"></a> [enable\_directory\_reader](#output\_enable\_directory\_reader) | Was the Active Directory Application granted Directory Reader role in Azure AD? |
| <a name="output_service_principal_id"></a> [service\_principal\_id](#output\_service\_principal\_id) | The Lacework Service Principal id |
<!-- END_TF_DOCS -->
