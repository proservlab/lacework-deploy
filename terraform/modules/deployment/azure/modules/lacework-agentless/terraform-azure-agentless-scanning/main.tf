# provider "azurerm" {
#   features {
#     resource_group {
#       /* scanner creates disks in the resource group. In regular circumstance those disks are
#       cleaned up by the scanner. However, if `terraform destroy` is run before the scanner
#       can do cleanup, the destroy will fail, because those disks aren't managed by Terraform.
#       Hence we turn off the deletion prevention here.
#       */
#       prevent_deletion_if_contains_resources = false
#     }
#   }
#   /* use the current resource manager subscription if it's not provided, otherwise  
#   extract the subscription id if it's in the fully qualified form ("/subscriptions/xxx"),
#   otherwise just use the subscription id as it is. 
#   */
#   subscription_id = var.scanning_subscription_id == "" ? null : try(
#     regex("^/subscriptions/([A-Za-z0-9-_]+)$", var.scanning_subscription_id)[0],
#     var.scanning_subscription_id
#   )
# }

data "lacework_user_profile" "current" {
}

/* used to get the current subscription info */
data "azurerm_subscription" "current" {
}

/* used to get all available subscriptions, in case var.subscriptions_list is not provided */
data "azurerm_subscriptions" "available" {
}

/* used to get the az logged in user info  */
data "azurerm_client_config" "current" {}

locals {
  suffix = length(var.global_module_reference.suffix) > 0 ? var.global_module_reference.suffix : (
    length(var.suffix) > 0 ? var.suffix : random_id.uniq.hex
  )
  prefix = length(var.global_module_reference.prefix) > 0 ? var.global_module_reference.prefix : var.prefix

  lacework_domain = length(var.global_module_reference.lacework_domain) > 0 ? var.global_module_reference.lacework_domain : var.lacework_domain
  lacework_account = length(var.global_module_reference.lacework_account) > 0 ? var.global_module_reference.lacework_account : (
    length(var.lacework_account) > 0 ? var.lacework_account : trimsuffix(data.lacework_user_profile.current.url, ".${var.lacework_domain}")
  )

  blob_container_name = length(var.global_module_reference.blob_container_name) > 0 ? var.global_module_reference.blob_container_name : (
    length(var.blob_container_name) > 0 ? var.blob_container_name : "${local.prefix}-bucket-${local.suffix}"
  )

  owners = length(var.owner_id) > 0 ? [var.owner_id, data.azurerm_client_config.current.object_id] : [data.azurerm_client_config.current.object_id]

  tenant_id                     = length(var.tenant_id) > 0 ? var.tenant_id : data.azurerm_subscription.current.tenant_id
  scanning_subscription_id      = data.azurerm_subscription.current.id
  scanning_subscription_id_only = regex("^/subscriptions/([A-Za-z0-9-_]+)$", local.scanning_subscription_id)[0]
  scanning_resource_group_name = length(var.global_module_reference.scanning_resource_group_name) > 0 ? var.global_module_reference.scanning_resource_group_name : (
    length(var.scanning_resource_group_name) > 0 ? var.scanning_resource_group_name : "${local.prefix}-agentless-${local.suffix}"
  )

  /* extract storage account name */
  storage_account_url_regex = "^(https://?)([^/.]+).[.]+$"
  matches                   = length(var.storage_account_url) == 0 ? [] : regex(local.storage_account_url_regex, var.storage_account_url)
  /* Note: only lower case letters and numbers allowed, length between 3 and 24 */
  storage_account_name = length(var.storage_account_url) == 0 ? "${local.prefix}scan${local.suffix}" : local.matches[length(local.matches) - 1]
  storage_account_url  = length(var.storage_account_url) > 0 ? var.storage_account_url : "https://${local.storage_account_name}.blob.core.windows.net"
  storage_account_id   = var.global ? azurerm_storage_account.scanning[0].id : var.global_module_reference.storage_account_id

  subscriptions_list_local = var.global ? var.subscriptions_list : var.global_module_reference.subscriptions_list
  provided_subscriptions_list = [for sub in local.subscriptions_list_local : sub if !(substr(sub, 0, 1) == "-")]
  /* if subscription list is provided, use it, otherwise, use all available subscriptions minus excluded subscriptions */
  excluded_subscriptions_list = [for sub in local.subscriptions_list_local : trimprefix(sub, "-") if(substr(sub, 0, 1) == "-")]
  included_subscriptions_list = local.integration_level == "TENANT" ? (
    length(local.provided_subscriptions_list) > 0 ? local.provided_subscriptions_list : tolist(setsubtract(
      toset([for sub in data.azurerm_subscriptions.available.subscriptions : sub.id]), /* all available subscriptions */
      toset(local.excluded_subscriptions_list)
  ))) : distinct(concat(local.provided_subscriptions_list, [local.scanning_subscription_id]))
  /* double forward slash to match "/", otherwise TF treats it as a regex */
  included_subscriptions_list_no_prefix = [for sub in local.included_subscriptions_list : replace(sub, "//subscriptions//", "")]
  excluded_subscriptions_list_no_prefix = [for sub in local.excluded_subscriptions_list : replace(sub, "//subscriptions//", "-")]

  // excluded subscriptions are passed in via env var and intentionally ommitted here
  monitored_role_scopes = local.included_subscriptions_list

  environment_variables = {
    STARTUP_PROVIDER                  = "AZURE"
    SECRET_ARN                        = local.key_vault_id
    AZURE_TENANT_ID                   = local.tenant_id
    AZURE_SCANNING_SUBSCRIPTION_ID    = local.scanning_subscription_id_only
    AZURE_SCANNER_RESOURCE_GROUP_NAME = local.scanning_resource_group_name
    AZURE_INTEGRATION_LEVEL           = local.integration_level
    AZURE_BLOB_CONTAINER_NAME         = local.blob_container_name
    LACEWORK_APISERVER                = "${local.lacework_account}.${local.lacework_domain}"
    LOCAL_STORAGE                     = "/tmp"
    STARTUP_SERVICE                   = "ORCHESTRATE"
    AZURE_STORAGE_ACCOUNT_URL         = local.storage_account_url
    SIDEKICK_BUCKET                   = local.blob_container_name
    SIDEKICK_REGION                   = local.region
    STARTUP_RUNMODE                   = "TASK"
    AZURE_CUSTOM_NETWORK              = local.custom_network
    AZURE_USER_IDENTITY               = local.sidekick_principal_name_fully_qualified
    AZURE_CLIENT_ID                   = local.sidekick_client_id
    AZURE_KEY_VAULT_SECRET_NAME       = local.key_vault_secret_name
    AZURE_KEY_VAULT_URI               = local.key_vault_uri
  }
  environment_variables_as_list = [for key, val in local.environment_variables : { name = key, value = val }]

  key_vault_id = var.global ? azurerm_key_vault.lw_orchestrate[0].id : (
    length(var.global_module_reference.key_vault_id) > 0 ? var.global_module_reference.key_vault_id : var.key_vault_id
  )
  key_vault_secret_name = var.global ? "${local.prefix}-secret-${local.suffix}" : var.global_module_reference.key_vault_secret_name
  key_vault_uri         = var.global ? azurerm_key_vault.lw_orchestrate[0].vault_uri : var.global_module_reference.key_vault_uri

  /* role_definition_id created as part of azurerm_role_definition creation contains an extra '|' character in the end, which needs to be removed (using split) */
  monitored_subscription_role_definition_id = var.global ? split("|", azurerm_role_definition.agentless_monitored_subscription[0].id)[0] : var.global_module_reference.monitored_subscription_role_definition_id
  scanning_subscription_role_definition_id  = var.global ? split("|", azurerm_role_definition.agentless_scanning_subscription[0].id)[0] : var.global_module_reference.scanning_subscription_role_definition_id

  sidekick_principal_id                   = length(var.global_module_reference.sidekick_principal_id) > 0 ? var.global_module_reference.sidekick_principal_id : azurerm_user_assigned_identity.sidekick[0].principal_id
  sidekick_principal_name                 = "${local.prefix}-identity-${local.suffix}"
  sidekick_principal_name_fully_qualified = "/subscriptions/${local.scanning_subscription_id_only}/resourceGroups/${local.scanning_resource_group_name}/providers/Microsoft.ManagedIdentity/userAssignedIdentities/${local.sidekick_principal_name}"

  sidekick_client_id = var.global ? azurerm_user_assigned_identity.sidekick[0].client_id : var.global_module_reference.sidekick_client_id

  custom_network = length(var.custom_network) > 0 ? var.custom_network : (var.regional ? tolist(azurerm_virtual_network.agentless_orchestrate[0].subnet)[0].id : "")

  region            = lower(replace(var.region, " ", ""))
  integration_level = upper(var.integration_level)
  lacework_integration_name_local = var.global ? var.lacework_integration_name : var.global_module_reference.lacework_integration_name

  version_file   = "${abspath(path.module)}/VERSION"
  module_name    = "terraform-azure-agentless-scanning"
  module_version = fileexists(local.version_file) ? file(local.version_file) : ""
}

/* When we are doing a non-global/regional deployment, we expect some global resources 
to have been created. One way to check that is to ensure we can reference them via
the global_module_reference attribute.
TODO: Unfortunately this wouldn't work because the `check` predicate is only supported after 
TF 1.5 but we need to be backward compatible. We should uncomment this once Terraform major 
version is upgraded.
*/
/* check "check_global_resource_condition" {
  assert {
    condition = var.global || (
      length(var.global_module_reference.storage_account_id) > 0 &&
      length(var.global_module_reference.scanning_subscription_role_definition_id) > 0 &&
      length(var.global_module_reference.monitored_subscription_role_definition_id) > 0 &&
      length(var.global_module_reference.blob_container_name) > 0 &&
      length(var.global_module_reference.key_vault_id) > 0 &&
      length(var.global_module_reference.sidekick_principal_id) > 0 &&
      length(var.global_module_reference.sidekick_client_id) > 0 &&
      length(var.global_module_reference.key_vault_secret_name) > 0 &&
      length(var.global_module_reference.key_vault_uri) > 0
    )
    error_message = "Some resources have not been referenced correctly during a non-global deployment"
  }
}
 */
resource "random_id" "uniq" {
  byte_length = 2
}

resource "azurerm_resource_group" "scanning_rg" {
  count = var.global ? 1 : 0

  name     = local.scanning_resource_group_name
  location = local.region
}

data "azurerm_resource_group" "scanning_rg" {
  count = var.global ? 0 : 1

  name = local.scanning_resource_group_name
}

// Lacework Cloud Account Integration
resource "lacework_integration_azure_agentless_scanning" "lacework_cloud_account" {
  count = var.global ? 1 : 0
  /* LW integration verifies that the storage account's existence using a registered
  app, hence the depency below 
  */
  depends_on = [
    azuread_service_principal.data_loader,
    azurerm_storage_container.scanning,
  ]

  name = local.lacework_integration_name_local
  credentials {
    client_id     = azuread_application.lw[0].client_id
    client_secret = azuread_service_principal_password.data_loader[0].value
  }
  integration_level            = local.integration_level
  blob_container_name          = local.blob_container_name
  scanning_subscription_id     = local.scanning_subscription_id_only
  tenant_id                    = local.tenant_id
  scanning_resource_group_name = local.scanning_resource_group_name
  storage_account_url          = local.storage_account_url
  scan_frequency               = var.scan_frequency_hours
  scan_containers              = var.scan_containers
  scan_host_vulnerabilities    = var.scan_host_vulnerabilities
  scan_multi_volume            = var.scan_multi_volume
  scan_stopped_instances       = var.scan_stopped_instances
  query_text                   = var.filter_query_text
  subscriptions_list = concat(
    local.included_subscriptions_list_no_prefix,
    local.excluded_subscriptions_list_no_prefix,
  )
}

/* **************** General **************** 
This section defines resources that are shared by individual sections down below
*/

resource "azuread_application" "lw" {
  count = var.global ? 1 : 0

  display_name = "laceworkagentless"
  owners       = local.owners
}

resource "azuread_service_principal" "data_loader" {
  count = var.global ? 1 : 0

  client_id                    = azuread_application.lw[0].client_id
  app_role_assignment_required = true
  use_existing                 = true
  owners                       = local.owners
  notification_email_addresses = length(var.notification_email) > 0 ? [var.notification_email] : []
  notes                        = "Used by Lacework data_loader to transfer analysis artifacts to Lacework"
}

resource "azuread_service_principal_password" "data_loader" {
  count = var.global ? 1 : 0

  service_principal_id = azuread_service_principal.data_loader[0].object_id
  end_date_relative    = "87600h" // expires in 10 years
}

resource "azurerm_user_assigned_identity" "sidekick" {
  count      = var.global ? 1 : 0
  depends_on = [azurerm_resource_group.scanning_rg]

  location            = local.region
  name                = local.sidekick_principal_name
  resource_group_name = local.scanning_resource_group_name
  tags                = var.tags
}

/* **************** End General **************** */


/* **************** Key Vault **************** 
Define the key vault which holds integration details 
*/
resource "azurerm_key_vault" "lw_orchestrate" {
  count      = var.global ? 1 : 0
  depends_on = [azurerm_resource_group.scanning_rg]

  name                       = "${local.prefix}-agentless-${local.suffix}"
  location                   = local.region
  resource_group_name        = local.scanning_resource_group_name
  tenant_id                  = local.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  tags                       = var.tags

  network_acls {
    default_action = "Allow"
    bypass         = "AzureServices"
  }
}

/* Note: access policies need to be defined separately from the key vault to 
avoid dependency cycles, otherwise the container app will need the key vault
id (as an env variable) to be created, while the key vault needs the container
app managed identity to create access policies.
 */
resource "azurerm_key_vault_access_policy" "access_for_sidekick" {
  count = var.global ? 1 : 0

  key_vault_id = local.key_vault_id
  tenant_id    = local.tenant_id
  object_id    = local.sidekick_principal_id

  secret_permissions = [
    "Set",
    "Delete",
    "Get",
    "List",
  ]
}

resource "azurerm_key_vault_access_policy" "access_for_user" {
  count = var.global ? 1 : 0

  key_vault_id = local.key_vault_id
  tenant_id    = local.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Set",
    "Delete",
    "Get",
    "List",
    /* recover and purge permissions make tearing down deployment smooth,
      but it's optional if the deployment is once and done
       */
    "Recover",
    "Purge",
  ]
}

/* assign key vault contributor role to the service principal */
resource "azurerm_role_assignment" "key_vault_sidekick" {
  count = var.global ? 1 : 0

  scope                = local.key_vault_id
  role_definition_name = "Key Vault Contributor"
  principal_id         = local.sidekick_principal_id
}

/* assign key vault contributor role to the current user */
resource "azurerm_role_assignment" "key_vault_user" {
  count = var.global ? 1 : 0

  scope                = local.key_vault_id
  role_definition_name = "Key Vault Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_key_vault_secret" "lw_orchestrate" {
  count = var.global ? 1 : 0
  depends_on = [
    lacework_integration_azure_agentless_scanning.lacework_cloud_account,
    azurerm_key_vault_access_policy.access_for_user
  ]

  /* stores credentials used to authenticate to LW API server */
  name         = local.key_vault_secret_name
  value        = <<EOF
   {
    "account": "${local.lacework_account}",
    "token": "${lacework_integration_azure_agentless_scanning.lacework_cloud_account[0].server_token}"
   }
  EOF
  key_vault_id = local.key_vault_id
}

/* **************** End Key Vault **************** */


/* **************** Storage **************** 
Define the blob storage account and assign corresponding role 
The storage account is used to store analysis data 
*/

resource "azurerm_storage_account" "scanning" {
  depends_on = [azurerm_resource_group.scanning_rg]
  count      = var.global ? 1 : 0

  name                = local.storage_account_name
  resource_group_name = local.scanning_resource_group_name
  location            = local.region
  account_tier        = "Standard"
  # Locally redundant (redundancy in primary region). The cheapest
  account_replication_type          = "LRS"
  infrastructure_encryption_enabled = var.enable_storage_infrastructure_encryption
  allow_nested_items_to_be_public   = false
  min_tls_version                   = "TLS1_2"
  enable_https_traffic_only         = true

  tags = var.tags
}

resource "azurerm_storage_container" "scanning" {
  count      = var.global ? 1 : 0
  depends_on = [azurerm_storage_account.scanning]

  name                  = local.blob_container_name
  storage_account_name  = local.storage_account_name
  container_access_type = "private"
}

resource "azurerm_role_assignment" "storage_sidekick" {
  count = var.global ? 1 : 0

  principal_id         = local.sidekick_principal_id
  role_definition_name = "Storage Blob Data Contributor"
  scope                = local.storage_account_id
}

resource "azurerm_role_assignment" "storage_data_loader" {
  count = var.global ? 1 : 0

  principal_id         = azuread_service_principal.data_loader[0].object_id
  role_definition_name = "Storage Blob Data Reader"
  scope                = local.storage_account_id
}
/* **************** End Storage **************** */

/* **************** Scanning **************** 
Define scanning related permissions and resources. We need to be able to enumerate compute 
instances as well as to create snapshots.
*/

resource "azurerm_role_assignment" "scanner" {
  count = var.global ? 1 : 0
  depends_on = [
    azurerm_role_definition.agentless_scanning_subscription[0],
    azurerm_user_assigned_identity.sidekick,
  ]

  principal_id       = local.sidekick_principal_id
  role_definition_id = local.scanning_subscription_role_definition_id
  scope              = local.scanning_subscription_id
}

resource "azurerm_role_assignment" "orchestrate" {
  for_each = var.global ? toset(local.included_subscriptions_list) : []
  depends_on = [
    azurerm_role_definition.agentless_monitored_subscription[0],
    azurerm_user_assigned_identity.sidekick,
  ]

  principal_id       = local.sidekick_principal_id
  role_definition_id = local.monitored_subscription_role_definition_id
  scope              = each.value
}

/* **************** End Scanning **************** */

resource "azurerm_network_security_group" "agentless_orchestrate" {
  depends_on = [azurerm_resource_group.scanning_rg]
  count      = var.regional && length(var.custom_network) == 0 ? 1 : 0

  name                = lower(replace("${local.prefix}-nsg-${local.suffix}-${local.region}", " ", ""))
  location            = local.region
  resource_group_name = local.scanning_resource_group_name

  security_rule {
    name                       = "Outbound_443"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "Internet"
  }
}

resource "azurerm_virtual_network" "agentless_orchestrate" {
  depends_on = [azurerm_resource_group.scanning_rg]
  count      = var.regional && length(var.custom_network) == 0 ? 1 : 0

  name                = length(var.custom_network) > 0 ? "" : lower(replace("${local.prefix}-virt-network-${local.suffix}-${local.region}", " ", ""))
  location            = local.region
  resource_group_name = local.scanning_resource_group_name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = length(var.custom_network) > 0 ? "" : lower(replace("${local.prefix}-subnet-${local.suffix}-${local.region}", " ", ""))
    address_prefix = "10.0.0.0/16"
    security_group = azurerm_network_security_group.agentless_orchestrate[0].id
  }
}

// Cloud Run service for Agentless Workload Scanning
resource "azurerm_log_analytics_workspace" "agentless_orchestrate" {
  depends_on = [azurerm_resource_group.scanning_rg]
  count      = var.regional && var.create_log_analytics_workspace ? 1 : 0

  name                = replace("${local.prefix}-log-${local.region}-${local.suffix}", " ", "-")
  location            = local.region
  resource_group_name = local.scanning_resource_group_name
}


resource "azurerm_container_app_environment" "agentless_orchestrate" {
  depends_on = [azurerm_resource_group.scanning_rg]
  count      = var.regional ? 1 : 0

  name                       = replace("${local.prefix}-service-${local.region}-${local.suffix}", " ", "-")
  location                   = local.region
  resource_group_name        = local.scanning_resource_group_name
  tags                       = var.tags
  log_analytics_workspace_id = var.create_log_analytics_workspace ? azurerm_log_analytics_workspace.agentless_orchestrate[0].id : null
}


// Cloud Scheduler job to perodically run the Azure Container App 
// https://learn.microsoft.com/en-us/rest/api/containerapps/preview/jobs/create-or-update?tabs=HTTP#jobconfiguration 
resource "azapi_resource" "container_app_job_agentless" {
  count = var.regional ? 1 : 0
  /* The container app needs the LW integration returned credentials to talk
  with LW servers, hence the dependency */
  depends_on = [
    lacework_integration_azure_agentless_scanning.lacework_cloud_account
  ]

  type = "Microsoft.App/jobs@2023-05-01"
  name = lower(replace("${var.prefix}-${local.region}-${local.suffix}", " ", "-"))
  identity {
    type         = "UserAssigned"
    identity_ids = [local.sidekick_principal_name_fully_qualified]
  }

  location  = local.region
  parent_id = var.global ? azurerm_resource_group.scanning_rg[0].id : data.azurerm_resource_group.scanning_rg[0].id
  tags      = var.tags

  body = jsonencode({
    properties = {
      configuration = {
        replicaRetryLimit = 0
        replicaTimeout    = 3600 /* seconds */
        scheduleTriggerConfig = {
          cronExpression         = "0 * * * *"
          parallelism            = 1
          replicaCompletionCount = 1
        }
        triggerType = "Schedule"
      }
      environmentId = azurerm_container_app_environment.agentless_orchestrate[0].id
      template = {
        containers = [
          {
            image = var.image_url
            name  = "sidekick"
            env   = local.environment_variables_as_list
            resources = {
              // max CPU/memory combination supported by container jobs 
              cpu    = 2,
              memory = "4Gi"
            }
          }
        ]
      }
    }
  })
}

data "lacework_metric_module" "lwmetrics" {
  name    = local.module_name
  version = local.module_version
}
