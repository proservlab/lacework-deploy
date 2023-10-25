locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  profile = coalesce(var.config.context.aws.profile_name, "false") == "false" ? null : var.config.context.aws.profile_name
  region = coalesce(var.config.context.aws.profile_name, "false") == "false" ? "us-east-1" : var.config.context.aws.region
}

provider "kubernetes" {
  alias = "main"
  config_path = local.default_kubeconfig
}
provider "kubernetes" {
  alias = "attacker"
  config_path = local.attacker_kubeconfig
}
provider "kubernetes" {
  alias = "target"
  config_path = local.target_kubeconfig
}

provider "helm" {
  alias = "main"
  kubernetes {
    config_path = local.default_kubeconfig
  }
}
provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = local.attacker_kubeconfig
  }
}
provider "helm" {
  alias = "target"
  kubernetes {
    config_path = local.target_kubeconfig
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
    "API-Key" = try(var.config.context.dynu_dns.api_key, ""),
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}