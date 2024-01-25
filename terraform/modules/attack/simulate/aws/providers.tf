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
  
  default_kubeconfig_path = try(local.default_infrastructure_deployed.aws.eks[0].kubeconfig_path, pathexpand("~/.kube/config"))
  attacker_kubeconfig_path = try(local.attacker_infrastructure_deployed.aws.eks[0].kubeconfig_path, pathexpand("~/.kube/config"))
  target_kubeconfig_path = try(local.target_infrastructure_deployed.aws.eks[0].kubeconfig_path, pathexpand("~/.kube/config"))
}

provider "kubernetes" {
  config_path = local.default_kubeconfig_path
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
    config_path = local.default_kubeconfig_path
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

provider "aws" {
  profile = var.default_aws_profile
  region = var.default_aws_region
}

provider "aws" {
  alias = "attacker"
  profile = var.attacker_aws_profile
  region = var.attacker_aws_region
}

provider "aws" {
  alias = "target"
  profile = var.target_aws_profile
  region = var.target_aws_region
}

provider "lacework" {
  profile    = var.default_lacework_profile
}

provider "restapi" {
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = try(local.default_infrastructure_config.context.dynu_dns.api_key, ""),
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}