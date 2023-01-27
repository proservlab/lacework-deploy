data "google_client_config" "provider" {}

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