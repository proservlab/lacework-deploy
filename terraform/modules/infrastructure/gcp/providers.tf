locals{
  default_kubeconfig_path = pathexpand("~/.kube/gcp-${var.config.context.global.environment}-${var.config.context.global.deployment}-kubeconfig")
  kubeconfig_path = try(module.gke[0].kubeconfig_path, local.default_kubeconfig_path)
}


provider "google" {
  credentials = can(length(var.config.context.gcp.project_id)) ? null : "{\"type\": \"service_account\", \"project_id\": \"default\"}"
  project = var.config.context.gcp.project_id
  region = var.config.context.gcp.region
}

provider "google" {
  alias = "lacework"
  credentials = can(length(var.config.context.gcp_audit_config.project_id)) ? null : "{\"type\": \"service_account\", \"project_id\": \"default\"}"
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
  account    = can(length(var.config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-secret"
}