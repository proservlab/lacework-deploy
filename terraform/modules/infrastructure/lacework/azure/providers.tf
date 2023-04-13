locals {
  subscription = coalesce(local.default_infrastructure_config.context.azure.subscription, "false") == "false" ? null : var.config.context.azure.subscription
  tenant = coalesce(local.default_infrastructure_config.context.azure.tenant, "false") == "false" ? null : var.config.context.azure.tenant
  region = coalesce(local.default_infrastructure_config.context.azure.region, "false") == "false" ? "West US 2" : var.config.context.azure.region

  default_kubeconfig_path = pathexpand("~/.kube/azure-${local.default_infrastructure_config.context.global.environment}-${local.default_infrastructure_config.context.global.deployment}-kubeconfig")
  attacker_default_kubeconfig_path = pathexpand("~/.kube/azure-attacker-${local.default_infrastructure_config.context.global.deployment}-kubeconfig")
  target_default_kubeconfig_path = pathexpand("~/.kube/azure-target-${local.default_infrastructure_config.context.global.deployment}-kubeconfig")
  
  kubeconfig_path = try(local.default_infrastructure_config.deployed_state[local.default_infrastructure_config.context.global.environment].aks[0].kubeconfig_path, local.default_kubeconfig_path)
  attacker_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["attacker"].aks[0].kubeconfig_path, local.attacker_default_kubeconfig_path)
  target_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["target"].aks[0].kubeconfig_path, local.target_default_kubeconfig_path)
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

