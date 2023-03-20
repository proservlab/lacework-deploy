locals {
  subscription = coalesce(local.default_infrastructure_config.context.azure.subscription, "false") == "false" ? null : local.default_infrastructure_config.context.azure.subscription
  tenant = coalesce(local.default_infrastructure_config.context.azure.tenant, "false") == "false" ? null : local.default_infrastructure_config.context.azure.tenant
  region = coalesce(local.default_infrastructure_config.context.azure.region, "false") == "false" ? "West US 2" : local.default_infrastructure_config.context.azure.region

  attacker_access_key = coalesce(local.attacker_infrastructure_config.context.azure.subscription, "false") != "false" ? null : local.attacker_infrastructure_config.context.azure.subscription
  attacker_secret_key = coalesce(local.attacker_infrastructure_config.context.azure.tenant, "false") != "false" ? null : local.attacker_infrastructure_config.context.azure.tenant
  attacker_profile = coalesce(local.attacker_infrastructure_config.context.azure.region, "false") == "false" ? "West US 2" :  local.attacker_infrastructure_config.context.azure.region

  target_access_key = coalesce(local.target_infrastructure_config.context.azure.subscription, "false") != "false" ? null : local.target_infrastructure_config.context.azure.subscription
  target_secret_key = coalesce(local.target_infrastructure_config.context.azure.tenant, "false") != "false" ? null : local.target_infrastructure_config.context.azure.tenant
  target_profile = coalesce(local.target_infrastructure_config.context.azure.region, "false") == "false" ? "West US 2" :  local.target_infrastructure_config.context.azure.region

  default_kubeconfig_path = pathexpand("~/.kube/azure-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
  attacker_default_kubeconfig_path = pathexpand("~/.kube/azure-attacker-${var.config.context.global.deployment}-kubeconfig")
  target_default_kubeconfig_path = pathexpand("~/.kube/azure-target-${var.config.context.global.deployment}-kubeconfig")
  
  kubeconfig_path = try(local.default_infrastructure_config.deployed_state[local.config.context.global.environment].aks[0].kubeconfig_path, local.default_kubeconfig_path)
  attacker_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["attacker"].aks[0].kubeconfig_path, local.attacker_default_kubeconfig_path)
  target_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["target"].aks[0].kubeconfig_path, local.target_default_kubeconfig_path)
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "azurerm" {
  features {}
}

provider "lacework" {
  profile    = local.default_infrastructure_config.context.lacework.profile_name
  account    = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-api-secret"
}