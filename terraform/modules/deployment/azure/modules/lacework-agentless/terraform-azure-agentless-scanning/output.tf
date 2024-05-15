output "agentless_credentials_client_secret" {
  value       = var.global ? azuread_service_principal_password.data_loader[0].value : ""
  description = "Client secret of the service principal of Lacework app"
  sensitive   = true
}

output "agentless_credentials_client_id" {
  value       = var.global ? azuread_service_principal.data_loader[0].client_id : ""
  description = "Client id of the service principal of Lacework app"
}

output "sidekick_client_id" {
  value       = local.sidekick_client_id
  description = "Client id of the managed identity running scanner"
}

output "key_vault_id" {
  value       = local.key_vault_id
  description = "The ID of the Key Vault that stores the LW credentials"
}

output "key_vault_secret_name" {
  value       = local.key_vault_secret_name
  description = "The name of the secret stored in key vault. The secret contains LW account authN details"
}

output "key_vault_uri" {
  value       = local.key_vault_uri
  description = "The URI of the key vault that stores LW account details"
}

output "scanning_resource_group_name" {
  value       = var.scanning_resource_group_name
  description = "Name of the resource group hosting the scanner"
}

output "scanning_resource_group_id" {
  value       = var.global ? azurerm_resource_group.scanning_rg[0].id : data.azurerm_resource_group.scanning_rg[0].id
  description = "Id of the resource group hosting the scanner"
}

output "storage_account_name" {
  value       = local.storage_account_name
  description = "The blob storage account for Agentless Workload Scanning data."
}

output "storage_account_id" {
  value       = local.storage_account_id
  description = "The ID of storage account used for scanning"
}

output "blob_container_name" {
  value       = local.blob_container_name
  description = "The blob container used to store Agentless Workload Scanning data"
}

output "lacework_account" {
  value       = local.lacework_account
  description = "Lacework Account Name for Integration."
}

output "lacework_domain" {
  value       = local.lacework_domain
  description = "Lacework Domain Name for Integration."
}

output "lacework_integration_name" {
  value       = local.lacework_integration_name_local
  description = "The name of the integration. Passed along in global module reference."
}

output "prefix" {
  value       = var.prefix
  description = "Prefix used to add uniqueness to resource names."
}

output "suffix" {
  value       = local.suffix
  description = "Suffix used to add uniqueness to resource names."
}

output "monitored_subscription_role_definition_id" {
  value       = local.monitored_subscription_role_definition_id
  description = "The id of the monitored subscription role definition"
}

output "scanning_subscription_role_definition_id" {
  value       = local.scanning_subscription_role_definition_id
  description = "The id of the scanning subscription role definition"
}

output "sidekick_principal_id" {
  value       = local.sidekick_principal_id
  description = "The principal id of the user identity used by agentless scanner"
}

output "subscriptions_list" {
  value = local.subscriptions_list_local
  description = "The subscriptions list in global module reference"
}
