locals {
  default_kubeconfig_path = pathexpand("~/.kube/gcp-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
  attacker_default_kubeconfig_path = pathexpand("~/.kube/gcp-attacker-${var.config.context.global.deployment}-kubeconfig")
  target_default_kubeconfig_path = pathexpand("~/.kube/gcp-target-${var.config.context.global.deployment}-kubeconfig")
  
  kubeconfig_path = try(local.default_infrastructure_config.deployed_state[local.config.context.global.environment].eks[0].kubeconfig_path, local.default_kubeconfig_path)
  attacker_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["attacker"].eks[0].kubeconfig_path, local.attacker_default_kubeconfig_path)
  target_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["target"].eks[0].kubeconfig_path, local.target_default_kubeconfig_path)
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