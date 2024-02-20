locals {
  subscription = try(length(local.default_infrastructure_config.context.azure.subscription), "false") == "false" ? null : local.default_infrastructure_config.context.azure.subscription
  tenant = try(length(local.default_infrastructure_config.context.azure.tenant), "false") == "false" ? null : local.default_infrastructure_config.context.azure.tenant
  region = try(length(local.default_infrastructure_config.context.azure.region), "false") == "false" ? "West US 2" : local.default_infrastructure_config.context.azure.region

  attacker_subscription = try(length(local.attacker_infrastructure_config.context.azure.subscription), "false") == "false" ? null : local.attacker_infrastructure_config.context.azure.subscription
  attacker_tenant = try(length(local.attacker_infrastructure_config.context.azure.tenant), "false") == "false" ? null : local.attacker_infrastructure_config.context.azure.tenant
  attacker_region = try(length(local.attacker_infrastructure_config.context.azure.region), "false") == "false" ? "West US 2" :  local.attacker_infrastructure_config.context.azure.region

  target_subscription = try(length(local.target_infrastructure_config.context.azure.subscription), "false") == "false" ? null : local.target_infrastructure_config.context.azure.subscription
  target_tenant = try(length(local.target_infrastructure_config.context.azure.tenant), "false") == "false" ? null : local.target_infrastructure_config.context.azure.tenant
  target_region = try(length(local.target_infrastructure_config.context.azure.region), "false") == "false" ? "West US 2" :  local.target_infrastructure_config.context.azure.region
}

provider "azurerm" {
  features {}
  tenant_id = var.default_azure_tenant
  subscription_id = var.default_azure_subscription
}

provider "azurerm" {
  alias = "attacker"
  features {}
  tenant_id = var.attacker_azure_tenant
  subscription_id = var.attacker_azure_subscription
}

provider "azurerm" {
  alias = "target"
  features {}
  tenant_id = var.target_azure_tenant
  subscription_id = var.target_azure_subscription
}