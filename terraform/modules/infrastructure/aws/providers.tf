locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  profile = coalesce(var.config.context.aws.profile_name, "false") == "false" ? null : var.config.context.aws.profile_name
  region = coalesce(var.config.context.aws.profile_name, "false") == "false" ? "us-east-1" : var.config.context.aws.region

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
  profile = local.profile
  region = local.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "lacework" {
  profile = var.config.context.lacework.profile_name
  account    = can(length(var.config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-secret"
}