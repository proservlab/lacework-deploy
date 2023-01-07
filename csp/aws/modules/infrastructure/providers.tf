provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "google" {
  alias = "lacework"
  project = var.config.context.lacework.gcp_audit_config.project_id
  region = var.config.context.gcp.region
}