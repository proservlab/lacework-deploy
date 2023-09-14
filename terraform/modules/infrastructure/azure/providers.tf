locals {
  subscription = try(length(var.config.context.azure.subscription), "false") == "false" ? null : var.config.context.azure.subscription
  tenant = try(length(var.config.context.azure.tenant), "false") == "false" ? null : var.config.context.azure.tenant
  region = try(length(var.config.context.azure.region), "false") == "false" ? "West US 2" : var.config.context.azure.region

  default_kubeconfig_path = pathexpand("~/.kube/azure-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
  # kubeconfig_path = try(module.aks[0].kubeconfig_path, local.default_kubeconfig_path)
  kubeconfig_path = local.default_kubeconfig_path
}

provider "kubernetes" {
  config_path = var.default_kubeconfig
}
provider "kubernetes" {
  alias = "attacker"
  config_path = var.attacker_kubeconfig
}
provider "kubernetes" {
  alias = "target"
  config_path = var.target_kubeconfig
}

provider "helm" {
  kubernetes {
    config_path = var.default_kubeconfig
  }
}
provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = var.attacker_kubeconfig
  }
}
provider "helm" {
  alias = "target"
  kubernetes {
    config_path = var.default_kubeconfig
  }
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

provider "lacework" {
  profile    = var.default_lacework_profile
}

provider "restapi" {
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = try(var.config.context.dynu_dns.api_key, ""),
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}