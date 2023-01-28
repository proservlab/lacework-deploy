locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = can(length(var.config.context.aws.profile_name)) ? null : "mock_access_key"
  secret_key = can(length(var.config.context.aws.profile_name)) ? null : "mock_secret_key"

  default_kubeconfig_path = pathexpand("~/.kube/aws-${var.config.context.global.environment}-${var.config.context.global.deployment}-kubeconfig")
  kubeconfig_path = try(module.eks[0].kubeconfig_path, local.default_kubeconfig_path)
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "aws" {
  profile = var.config.context.aws.profile_name
  region = var.config.context.aws.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "lacework" {
  profile = var.config.context.lacework.profile_name
}