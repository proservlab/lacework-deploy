locals {
  subscription = coalesce(var.config.context.azure.subscription, "false") == "false" ? null : var.config.context.azure.subscription
  tenant = coalesce(var.config.context.azure.tenant, "false") == "false" ? null : var.config.context.azure.tenant
  region = coalesce(var.config.context.azure.region, "false") == "false" ? "West US 2" : var.config.context.azure.region

  default_kubeconfig_path = pathexpand("~/.kube/azure-${var.config.context.global.environment}-${var.config.context.global.deployment}-kubeconfig")
  # kubeconfig_path = try(module.aks[0].kubeconfig_path, local.default_kubeconfig_path)
  kubeconfig_path = local.default_kubeconfig_path
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
  profile    = var.config.context.lacework.profile_name
  account    = can(length(var.config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-secret"
}