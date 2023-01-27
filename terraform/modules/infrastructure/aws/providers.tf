locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = can(length(var.config.context.aws.profile_name)) ? null : "mock_access_key"
  secret_key = can(length(var.config.context.aws.profile_name)) ? null : "mock_secret_key"
}

data "aws_eks_cluster" "cluster" {
  count = length(module.eks) > 0 ? 1 : 0
  name = "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
  depends_on = [
    module.eks
  ]
}

data "aws_eks_cluster_auth" "cluster" {
  count = length(module.eks) > 0 ? 1 : 0
  name = "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"

  depends_on = [
    module.eks
  ]
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.cluster[0].endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.cluster[0].token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.cluster[0].endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster[0].certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.cluster[0].token
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