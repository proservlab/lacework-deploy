locals{
  kubeconfig_path = fileexists(try(module.gke[0].kubeconfig_path,"")) ? module.eks[0].kubeconfig_path : pathexpand("~/.kube/gcp-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
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