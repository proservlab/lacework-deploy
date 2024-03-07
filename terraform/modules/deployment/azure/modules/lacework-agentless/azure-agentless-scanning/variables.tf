variable "lacework_account" {
  type        = string
  description = "The name of the Lacework account with which to integrate."
  default     = ""
}

/* TODO: check that this is not set in regional resource */
variable "lacework_integration_name" {
  type        = string
  description = "The name of the Lacework cloud account integration. Should only be set in global resource"
  default     = "azure-agentless-scanning"
}


variable "lacework_domain" {
  type        = string
  description = "The domain of the Lacework account with with to integrate."
  default     = "lacework.net"
}

variable "prefix" {
  type        = string
  description = "A string to be prefixed to the name of all new resources."
  default     = "lacework"

  validation {
    condition     = length(regexall(".*lacework.*", var.prefix)) > 0
    error_message = "The prefix value must include the term 'lacework'."
  }
}

variable "suffix" {
  type        = string
  description = "A string to be appended to the end of the name of all new resources."
  default     = ""

  validation {
    condition     = length(var.suffix) == 0 || length(var.suffix) > 4
    error_message = "If the suffix value is set then it must be at least 4 characters long."
  }
}

variable "key_vault_id" {
  type        = string
  description = "The ID of the Key Vault containing the Lacework Account and Auth Token"
  default     = ""
}

# Scanner configuration 
# TODO: update this to Azure registry when we have it 
variable "image_url" {
  type        = string
  description = "The container image url for Lacework Agentless Workload Scanning."
  default     = "public.ecr.aws/p5r4i7k7/sidekick:latest"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "Set of tags which will be added to the resources managed by the module."
}

variable "custom_network" {
  type        = string
  default     = ""
  description = "The name of the custom Azure Virtual Network subnet. Make sure it allows egress traffic on port 443. Leave empty to create a new one."
  validation {
    condition = length(var.custom_network) == 0 || can(
      regex("^/subscriptions/.*/resourceGroups/.*/providers/Microsoft.Network/virtualNetworks/.*/subnets/.*$", var.custom_network)
    )
    error_message = "Incorrectly formatted network input. Use a full Resource ID in this format: /subscriptions/<subscription_id>/resourceGroups/<rg_id>/providers/Microsoft.Network/virtualNetworks/<vnet_id>/subnets/<subnet_id>."
  }
}

variable "region" {
  type        = string
  default     = "westus2"
  description = "The region where LW scanner is deployed to"
}

variable "notification_email" {
  type        = string
  default     = ""
  description = "Used for receiving notification on key updates such as those to service principal"
}

variable "owner_id" {
  type        = string
  default     = ""
  description = "Owner for service account created. Azure recommends having one"
  validation {
    condition     = can(regex("^[a-z0-9-]*$", var.owner_id))
    error_message = "Owner id needs to be of format xxxx-xxxx-xxxx-xxxx-xxxxx."
  }
}


/* 
To support multi-region deployment, we'll need to create some resource multiple times (one resource each region),
while other resources will be created only once and used by all regions globally. During deployment, the latter 
needs to be created first, and those resources will have their reference names/ids passed to the creation of resources 
in other regions, and there those global resources won't be creted again. We use `global` to flag whether 
the current deployment should create those global resources.
Here's a resource run-down:
Global resources:
  - Resource Group
  - Key Vault
  - Custom Roles
  - Storage Account

Regional resources:
  - Container App Jobs
 */

variable "global" {
  type        = bool
  default     = false
  description = "Whether we create global resources for this deployment. Defaults to `false`"
}

variable "regional" {
  type        = bool
  default     = true
  description = "Whether or not to create regional resources. Defaults to `true`."
}


/* **************** Scanner Knobs **************** 
This section defines knobs to customize the scanner
*/

variable "scan_containers" {
  type        = bool
  description = "Whether to includes scanning for containers.  Defaults to `true`."
  default     = true
}

variable "scan_host_vulnerabilities" {
  type        = bool
  description = "Whether to includes scanning for host vulnerabilities.  Defaults to `true`."
  default     = true
}

variable "scan_multi_volume" {
  type        = bool
  description = "Whether to scan secondary volumes. Defaults to `false`."
  default     = false
}

variable "scan_stopped_instances" {
  type        = bool
  description = "Whether to scan stopped instances. Defaults to `true`."
  default     = true
}

variable "scan_frequency_hours" {
  type        = number
  description = "How often in hours the scan will run in hours. Defaults to `24`."
  default     = 24

  validation {
    condition = (
      var.scan_frequency_hours == 24 ||
      var.scan_frequency_hours == 12 ||
      var.scan_frequency_hours == 6
    )
    error_message = "The scan frequency must be 6, 12, or 24 hours."
  }
}
/* **************** End Scanner Knobs **************** */



/* **************** Scanner Resources **************** 
This section defines variables used for initiating scanning
*/

variable "integration_level" {
  type        = string
  description = "If we are integrating into a subscription or tenant. Valid values are 'SUBSCRIPTION' or 'TENANT'"
  validation {
    condition     = upper(var.integration_level) == "SUBSCRIPTION" || upper(var.integration_level) == "TENANT"
    error_message = "Valid values are 'SUBSCRIPTION' or 'TENANT'."
  }
}

variable "tenant_id" {
  type        = string
  default     = ""
  description = "TenantId where LW Sidekick is deployed"
}

variable "scanning_subscription_id" {
  type        = string
  default     = ""
  description = "SubcriptionId where LW Sidekick is deployed. Leave blank to use the current one used by Azure Resource Manager. Show it through `az account show`"
}

variable "scanning_resource_group_name" {
  type        = string
  default     = ""
  description = "The name of the resource group where LW sidekick is deployed. Leave blank to create a new one"
}

variable "create_log_analytics_workspace" {
  type        = bool
  default     = false
  description = "Creates a log analytics workspace to see container logs. Defaults to false to avoid charging"
}

/* **************** End Scanner Resources **************** */


/* **************** Monitored Section **************** 
Define what resources should be monitored/scanned 
*/

/* TODO: add a check that the subscriptions_list is not set for non-global resources */
variable "subscriptions_list" {
  type        = set(string)
  description = "List of subscriptions to be scanned. Prefix a subscription with '-' to exclude it from scanning. Set only for global resource"
  default     = []
  validation {
    condition     = alltrue([for sub in var.subscriptions_list : can(regex("^-?/subscriptions/.*", sub))])
    error_message = "Need to be a list of fully qualified subscriptions (starting with '/subscriptions/', with optional '-' prefix."
  }
}
/* **************** End Monitored Section **************** */


/* **************** Storage Section **************** 
Define resources used for storage 
*/

variable "blob_container_name" {
  type        = string
  default     = ""
  description = "name of the blob container used for storing analysis artifacts. Leave blank to generate one"
}

variable "storage_account_url" {
  type        = string
  description = "url of the storage account used for storing analysis artifacts."
  default     = ""
  validation {
    condition     = length(var.storage_account_url) == 0 || can(regex("^(https://?)[A-Za-z0-9.-]+(:[0-9]+)?(/[\\S]*)?$", var.storage_account_url))
    error_message = "Please provide a valid storage account url or leave it blank to create a new one."
  }
}

variable "enable_storage_infrastructure_encryption" {
  type        = bool
  description = "enable Azure storage account-level infrastructure encryption. Defaults to false"
  default     = false
}

/* **************** End Storage Section **************** */

variable "filter_query_text" {
  type        = string
  description = "The LQL query to constrain the scanning to specific resources. If left blank, Lacework will scan all resources available to the account or organization. For more information, see [Limit Scanned Workloads](https://docs.lacework.net/onboarding/lacework-console-agentless-workload-scanning#aws---limit-scanned-workloads)."
  default     = ""
}

variable "global_module_reference" {
  type = object({
    scanning_resource_group_name              = string
    key_vault_id                              = string
    key_vault_uri                             = string
    key_vault_secret_name                     = string
    lacework_account                          = string
    lacework_domain                           = string
    lacework_integration_name                 = string
    storage_account_name                      = string
    storage_account_id                        = string
    blob_container_name                       = string
    prefix                                    = string
    suffix                                    = string
    monitored_subscription_role_definition_id = string
    scanning_subscription_role_definition_id  = string
    sidekick_principal_id                     = string
    sidekick_client_id                        = string
    subscriptions_list                        = set(string)
  })
  default = {
    scanning_resource_group_name              = ""
    key_vault_id                              = ""
    key_vault_uri                             = ""
    key_vault_secret_name                     = ""
    lacework_account                          = ""
    lacework_domain                           = ""
    lacework_integration_name                 = ""
    storage_account_name                      = ""
    storage_account_id                        = ""
    blob_container_name                       = ""
    prefix                                    = ""
    suffix                                    = ""
    monitored_subscription_role_definition_id = ""
    scanning_subscription_role_definition_id  = ""
    sidekick_principal_id                     = ""
    sidekick_client_id                        = ""
    subscriptions_list                        = []
  }
  description = "A reference to the global lacework_azure_agentless_scanning module for this account."
}