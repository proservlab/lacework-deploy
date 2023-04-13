locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  profile = coalesce(var.config.context.aws.profile_name, "false") == "false" ? null : var.config.context.aws.profile_name
  region = coalesce(var.config.context.aws.profile_name, "false") == "false" ? "us-east-1" : var.config.context.aws.region

  kubeconfig_path = pathexpand("~/.kube/config")
}

provider "kubernetes" {
  config_path = var.default_kubeconfig
}
provider "kubernetes" {
  alias = "attacker"
  config_path = var.attacker_kubeconfig
}
provider "kubernetes" {
  alias = "target"
  config_path = var.target_kubeconfig
}

provider "helm" {
  kubernetes {
    config_path = var.default_kubeconfig
  }
}
provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = var.attacker_kubeconfig
  }
}
provider "helm" {
  alias = "target"
  kubernetes {
    config_path = var.default_kubeconfig
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
    "API-Key" = var.config.context.dynu_dns.api_token,
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}