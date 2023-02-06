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
  credentials = can(length(var.config.context.lacework.gcp_audit_config.project_id)) ? null : "{\"type\": \"service_account\", \"project_id\": \"default\"}"
  project = var.config.context.lacework.gcp_audit_config.project_id
  region = var.config.context.gcp.region
}