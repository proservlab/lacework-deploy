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

  default_kubeconfig_path = pathexpand("~/.kube/aws-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
  attacker_default_kubeconfig_path = pathexpand("~/.kube/aws-attacker-${var.config.context.global.deployment}-kubeconfig")
  target_default_kubeconfig_path = pathexpand("~/.kube/aws-target-${var.config.context.global.deployment}-kubeconfig")
  
  kubeconfig_path = try(local.default_infrastructure_config.deployed_state[local.config.context.global.environment].eks[0].kubeconfig_path, local.default_kubeconfig_path)
  attacker_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["attacker"].eks[0].kubeconfig_path, local.attacker_default_kubeconfig_path)
  target_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["target"].eks[0].kubeconfig_path, local.target_default_kubeconfig_path)
}

provider "aws" {
  profile                     = local.profile
  region                      = local.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

provider "aws" {
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
  alias = "target"
  profile                     = local.target_profile
  region                      = local.target_region
  access_key                  = local.target_access_key
  secret_key                  = local.target_secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "kubernetes" {
  alias = "attacker"
  config_path = local.attacker_kubeconfig_path
}

provider "kubernetes" {
  alias = "target"
  config_path = local.target_kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}

provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = local.attacker_kubeconfig_path
  }
}

provider "helm" {
  alias = "target"
  kubernetes {
    config_path = local.target_kubeconfig_path
  }
}