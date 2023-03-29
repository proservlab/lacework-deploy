locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  
  kubeconfig_path = pathexpand("~/.kube/config")
}

data "aws_eks_cluster" "cluster" {
  count = local.kube_count
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster-auth" {
  count = local.kube_count
  name = var.cluster_name
}

provider "kubernetes" {
  host                    = local.kube_count > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
  cluster_ca_certificate  = local.kube_count > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : null
  token                   = local.kube_count > 0 ? data.aws_eks_cluster_auth.cluster-auth[0].token : null
  config_path             = local.kube_count > 0 ? null : local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    host                    = local.kube_count > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
    cluster_ca_certificate  = local.kube_count > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : null
    token                   = local.kube_count > 0 ? data.aws_eks_cluster_auth.cluster-auth[0].token : null
    config_path             = local.kube_count > 0 ? null : local.kubeconfig_path
  }
}

provider "aws" {
  max_retries = 40

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
  profile    = var.config.context.lacework.profile_name
  account    = can(length(var.config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-secret"
}