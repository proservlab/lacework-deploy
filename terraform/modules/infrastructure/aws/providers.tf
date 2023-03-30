locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  profile = coalesce(var.config.context.aws.profile_name, "false") == "false" ? null : var.config.context.aws.profile_name
  region = coalesce(var.config.context.aws.profile_name, "false") == "false" ? "us-east-1" : var.config.context.aws.region

  kubeconfig_path = pathexpand("~/.kube/config")
}

data "aws_eks_clusters" "deployed" {}

locals {
  cluster_name  = coalesce(try(module.eks[0].cluster_name, null), "${local.default_infrastructure_config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}")
  cluster_count = length([ for cluster in data.aws_eks_clusters.deployed.names: cluster if cluster == local.cluster_name ])
}

data "aws_eks_cluster" "cluster" {
  count = local.cluster_count
  name = local.cluster_name
}

data "aws_eks_cluster_auth" "cluster-auth" {
  count = local.cluster_count
  name = local.cluster_name
}

provider "kubernetes" {
  host                    = local.cluster_count > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
  cluster_ca_certificate  = local.cluster_count > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : null
  token                   = local.cluster_count > 0 ? data.aws_eks_cluster_auth.cluster-auth[0].token : null
  config_path             = local.cluster_count > 0 ? null : local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    host                    = local.cluster_count > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
    cluster_ca_certificate  = local.cluster_count > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : null
    token                   = local.cluster_count > 0 ? data.aws_eks_cluster_auth.cluster-auth[0].token : null
    config_path             = local.cluster_count > 0 ? null : local.kubeconfig_path
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