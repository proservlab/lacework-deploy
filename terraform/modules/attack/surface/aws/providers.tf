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

provider "kubernetes" {
  alias = "main"
  host                   = try(length(local.cluster_endpoint), "false" ) != "false" ? local.cluster_endpoint : "http://localhost"
  cluster_ca_certificate = try(length(local.cluster_ca_cert), "false" ) != "false" ? base64decode(local.cluster_ca_cert) : null
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["--region", local.aws_region, "--profile", local.aws_profile_name, "eks", "get-token", "--cluster-name", local.cluster_name] 
    command     = "aws"
  }
}

provider "helm" {
  alias = "main"
  kubernetes {
    host                   = try(length(local.cluster_endpoint), "false" ) != "false" ? local.cluster_endpoint : "http://localhost"
    cluster_ca_certificate = try(length(local.cluster_ca_cert), "false" ) != "false" ? base64decode(local.cluster_ca_cert) : null
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["--region", local.aws_region, "--profile", local.aws_profile_name, "eks", "get-token", "--cluster-name", local.cluster_name]
      command     = "aws"
    }
  }
}

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

provider "lacework" {
  profile    = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? local.default_infrastructure_config.context.lacework.profile_name : null
  account    = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(local.default_infrastructure_config.context.lacework.profile_name)) ? null : "my-api-secret"
}