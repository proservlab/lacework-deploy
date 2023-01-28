locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = can(length(local.default_infrastructure_config.context.aws.profile_name)) ? null : "mock_access_key"
  secret_key = can(length(local.default_infrastructure_config.context.aws.profile_name)) ? null : "mock_secret_key"

  default_kubeconfig_path = pathexpand("~/.kube/aws-${var.config.context.global.environment}-${var.config.context.global.deployment}-kubeconfig")
  attacker_default_kubeconfig_path = pathexpand("~/.kube/aws-attacker-${var.config.context.global.deployment}-kubeconfig")
  target_default_kubeconfig_path = pathexpand("~/.kube/aws-target-${var.config.context.global.deployment}-kubeconfig")
  
  kubeconfig_path = try(local.default_infrastructure_config.deployed_state[var.config.context.global.environment].eks[0].kubeconfig_path, local.default_kubeconfig_path)
  attacker_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["attacker"].eks[0].kubeconfig_path, local.attacker_default_kubeconfig_path)
  target_kubeconfig_path = try(local.default_infrastructure_config.deployed_state["target"].eks[0].kubeconfig_path, local.target_default_kubeconfig_path)
}

provider "aws" {
  profile = local.default_infrastructure_config.context.aws.profile_name
  region = local.default_infrastructure_config.context.aws.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "aws" {
  alias = "attacker"
  profile = local.attacker_infrastructure_config.context.aws.profile_name
  region = local.attacker_infrastructure_config.context.aws.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "aws" {
  alias = "target"
  profile = local.target_infrastructure_config.context.aws.profile_name
  region = local.target_infrastructure_config.context.aws.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
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