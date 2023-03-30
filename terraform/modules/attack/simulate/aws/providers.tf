locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(local.default_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(local.default_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  profile = coalesce(local.default_infrastructure_config.context.aws.profile_name, "false") == "false" ? null : local.default_infrastructure_config.context.aws.profile_name
  region = coalesce(local.default_infrastructure_config.context.aws.profile_name, "false") == "false" ? "us-east-1" : local.default_infrastructure_config.context.aws.region

  attacker_access_key = coalesce(local.attacker_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  attacker_secret_key = coalesce(local.attacker_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  attacker_profile = coalesce(local.attacker_infrastructure_config.context.aws.profile_name, "false") == "false" ? null : local.attacker_infrastructure_config.context.aws.profile_name
  attacker_region = coalesce(local.attacker_infrastructure_config.context.aws.profile_name, "false") == "false" ? "us-east-1" : local.attacker_infrastructure_config.context.aws.region

  target_access_key = coalesce(local.target_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  target_secret_key = coalesce(local.target_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  target_profile = coalesce(local.target_infrastructure_config.context.aws.profile_name, "false") == "false" ? null : local.target_infrastructure_config.context.aws.profile_name
  target_region = coalesce(local.target_infrastructure_config.context.aws.profile_name, "false") == "false" ? "us-east-1" : local.target_infrastructure_config.context.aws.region
  
  kubeconfig_path = pathexpand("~/.kube/config")
}

data "aws_eks_clusters" "deployed" {}

locals {
  cluster_name  = coalesce(var.cluster_name, "${local.default_infrastructure_config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}")
  cluster_count = length([ for cluster in data.aws_eks_clusters.deployed.names: cluster if cluster == local.cluster_name ])
}

data "aws_eks_cluster" "cluster" {
  count = local.cluster_count
  name = local.default_infrastructure_deployed.aws.eks[0].cluster_name
}

data "aws_eks_cluster_auth" "cluster-auth" {
  count = local.cluster_count
  name = local.default_infrastructure_deployed.aws.eks[0].cluster_name
}

provider "kubernetes" {
  config_context_cluster = local.cluster_count > 0 ? data.aws_eks_cluster.cluster[0].arn : null
    config_path = pathexpand("~/.kube/config")
}

provider "helm" {
  kubernetes {
    config_context_cluster = local.cluster_count > 0 ? data.aws_eks_cluster.cluster[0].arn : null
    config_path = pathexpand("~/.kube/config")
  }
}

# provider "kubernetes" {
#   host                    = local.cluster_count > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
#   cluster_ca_certificate  = local.cluster_count > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : null
#   token                   = local.cluster_count > 0 ? data.aws_eks_cluster_auth.cluster-auth[0].token : null
#   config_path             = local.cluster_count > 0 ? null : local.kubeconfig_path
# }

# provider "helm" {
#   kubernetes {
#     host                    = local.cluster_count > 0 ? data.aws_eks_cluster.cluster[0].endpoint : null
#     cluster_ca_certificate  = local.cluster_count > 0 ? base64decode(data.aws_eks_cluster.cluster[0].certificate_authority.0.data) : null
#     token                   = local.cluster_count > 0 ? data.aws_eks_cluster_auth.cluster-auth[0].token : null
#     config_path             = local.cluster_count > 0 ? null : local.kubeconfig_path
#   }
# }

provider "aws" {
  max_retries = 40

  profile                     = local.profile
  region                      = local.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

provider "aws" {
  max_retries = 40

  alias = "attacker"
  profile                     = local.attacker_profile
  region                      = local.attacker_region
  access_key                  = local.attacker_access_key
  secret_key                  = local.attacker_secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

provider "aws" {
  max_retries = 40

  alias = "target"
  profile                     = local.target_profile
  region                      = local.target_region
  access_key                  = local.target_access_key
  secret_key                  = local.target_secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}