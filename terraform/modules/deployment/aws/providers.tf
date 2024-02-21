provider "kubernetes" {
  alias = "attacker"
  config_path = local.attacker_kubeconfig
}
provider "kubernetes" {
  alias = "target"
  config_path = local.target_kubeconfig
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
  alias = "attacker"
  profile    = var.attacker_lacework_profile
}
provider "lacework" {
  alias = "target"
  profile    = var.target_lacework_profile
}
provider "restapi" {
  alias = "attacker"
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = try(local.attacker_default_infrastructure_config.context.dynu_dns.api_key, ""),
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}

provider "restapi" {
  alias = "target"
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = try(local.target_infrastructure_config.context.dynu_dns.api_key, ""),
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}