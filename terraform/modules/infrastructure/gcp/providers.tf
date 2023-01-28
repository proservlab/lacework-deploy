locals{
  default_kubeconfig_path = pathexpand("~/.kube/gcp-${var.config.context.global.environment}-${var.config.context.global.deployment}-kubeconfig")
  kubeconfig_path = try(module.gke[0].kubeconfig_path, local.default_kubeconfig_path)
}

provider "google" {
  project = var.config.context.gcp.project_id
  region = var.config.context.gcp.region
}

provider "google" {
  alias = "lacework"
  project = var.config.context.lacework.gcp_audit_config.project_id
  region = var.config.context.gcp.region
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "lacework" {
  profile = var.config.context.lacework.profile_name
}