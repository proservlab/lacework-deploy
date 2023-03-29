locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  profile = coalesce(var.config.context.aws.profile_name, "false") == "false" ? null : var.config.context.aws.profile_name
  region = coalesce(var.config.context.aws.profile_name, "false") == "false" ? "us-east-1" : var.config.context.aws.region

  default_kubeconfig_path = pathexpand("~/.kube/aws-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
  attacker_default_kubeconfig_path = pathexpand("~/.kube/aws-attacker-${var.config.context.global.deployment}-kubeconfig")
  target_default_kubeconfig_path = pathexpand("~/.kube/aws-target-${var.config.context.global.deployment}-kubeconfig")
  
  kube_count = (local.default_infrastructure_config.context.global.enable_all == true) || (local.default_infrastructure_config.context.global.disable_all != true && local.default_infrastructure_config.context.aws.eks.enabled == true ) ? 1 : 0
}

data "aws_eks_cluster" "cluster" {
  count = local.kube_count
  name = "${local.default_infrastructure_config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
}

data "aws_eks_cluster_auth" "cluster-auth" {
  count = local.kube_count
  name = "${local.default_infrastructure_config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
}

provider "kubernetes" {
  host                    = local.kube_count > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
  cluster_ca_certificate  = local.kube_count > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : null
  token                   = local.kube_count > 0 ? data.aws_eks_cluster_auth.cluster-auth[0].token : null
  config_path             = local.kube_count > 0 ? null : local.default_kubeconfig_path
}

provider "helm" {
  kubernetes {
    host                    = local.kube_count > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
    cluster_ca_certificate  = local.kube_count > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : null
    token                   = local.kube_count > 0 ? data.aws_eks_cluster_auth.cluster-auth[0].token : null
    config_path             = local.kube_count > 0 ? null : local.default_kubeconfig_path
  }
}

provider "aws" {
  max_retries = 40

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
  profile    = var.config.context.lacework.profile_name
  account    = can(length(var.config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-secret"
}

provider "restapi" {
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = var.config.context.dynu_dns.api_token,
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}