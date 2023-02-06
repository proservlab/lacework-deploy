locals {
  default_kubeconfig_path = pathexpand("~/.kube/gcp-${var.config.context.global.environment}-${var.config.context.global.deployment}-kubeconfig")
  attacker_default_kubeconfig_path = pathexpand("~/.kube/gcp-attacker-${var.config.context.global.deployment}-kubeconfig")
  target_default_kubeconfig_path = pathexpand("~/.kube/gcp-target-${var.config.context.global.deployment}-kubeconfig")
  
  kubeconfig_path = try(local.default_infrastructure_config.deployed_state[var.config.context.global.environment].eks[0].kubeconfig_path, local.default_kubeconfig_path)
  attacker_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["attacker"].eks[0].kubeconfig_path, local.attacker_default_kubeconfig_path)
  target_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["target"].eks[0].kubeconfig_path, local.target_default_kubeconfig_path)
}

provider "google" {
  credentials = can(length(local.default_infrastructure_config.context.gcp.project_id)) ? null : "{\"type\": \"service_account\", \"project_id\": \"default\"}"
  project = local.default_infrastructure_config.context.gcp.project_id
  region = local.default_infrastructure_config.context.gcp.region
}

provider "google" {
  alias = "attacker"
  credentials = can(length(local.attacker_infrastructure_config.context.gcp.project_id)) ? null : "{\"type\": \"service_account\", \"project_id\": \"default\"}"
  project = local.attacker_infrastructure_config.context.gcp.project_id
  region = local.attacker_infrastructure_config.context.gcp.region
}

provider "google" {
  alias = "target"
  credentials = can(length(local.target_infrastructure_config.context.gcp.project_id)) ? null : "{\"type\": \"service_account\", \"project_id\": \"default\"}"
  project = local.target_infrastructure_config.context.gcp.project_id
  region = local.target_infrastructure_config.context.gcp.region
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "kubernetes" {
  alias = "attacker"
  config_path = local.attacker_kubeconfig_path
}

provider "kubernetes" {
  alias = "target"
  config_path = local.target_kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = local.attacker_kubeconfig_path
  }
}

provider "helm" {
  alias = "target"
  kubernetes {
    config_path = local.target_kubeconfig_path
  }
}