locals {
  default_kubeconfig_path = pathexpand("~/.kube/gcp-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
  attacker_default_kubeconfig_path = pathexpand("~/.kube/gcp-attacker-${var.config.context.global.deployment}-kubeconfig")
  target_default_kubeconfig_path = pathexpand("~/.kube/gcp-target-${var.config.context.global.deployment}-kubeconfig")
  
  kubeconfig_path = try(local.default_infrastructure_config.deployed_state[local.config.context.global.environment].gke[0].kubeconfig_path, local.default_kubeconfig_path)
  attacker_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["attacker"].gke[0].kubeconfig_path, local.attacker_default_kubeconfig_path)
  target_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["target"].gke[0].kubeconfig_path, local.target_default_kubeconfig_path)
}

provider "kubernetes" {
  alias = "main"
  config_path = var.default_kubeconfig
}

provider "helm" {
  alias = "main"
  kubernetes {
    config_path = var.default_kubeconfig
  }
}

provider "google" {
  project = var.default_gcp_project
  region = var.default_gcp_region
}

provider "google" {
  alias = "attacker"
  project = var.attacker_gcp_project
  region = var.attacker_gcp_region
}

provider "google" {
  alias = "target"
  project = var.target_gcp_project
  region = var.target_gcp_region
}

provider "restapi" {
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  rate_limit           = 5
  timeout              = 120
  debug                = false

  headers = {
    "API-Key" = try(local.default_infrastructure_config.context.dynu_dns.api_key, ""),
    "Content-Type" = "application/json",
    "accept" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}