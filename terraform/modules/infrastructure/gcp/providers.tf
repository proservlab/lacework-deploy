locals{
  kubeconfig_path = pathexpand("~/.kube/gcp-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
}

# create kubeconfig
resource "local_file" "kubeconfig" {
  content  = ""
  filename = local.kubeconfig_path
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