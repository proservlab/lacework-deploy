provider "kubernetes" {
  alias = "attacker"
  config_path = try(module.attacker-eks[0].kubeconfig_path, local.attacker_kubeconfig)
  config_context = try(module.attacker-eks[0].cluster.arn, null)
}
provider "kubernetes" {
  alias = "target"
  config_path = try(module.target-eks[0].kubeconfig_path, local.target_kubeconfig)
  config_context = try(module.target-eks[0].cluster.arn, null)
}
provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = try(module.attacker-eks[0].kubeconfig_path, local.attacker_kubeconfig)
    config_context = try(module.attacker-eks[0].cluster.arn, null)
  }
}
provider "helm" {
  alias = "target"
  kubernetes {
    config_path = try(module.target-eks[0].kubeconfig_path, local.target_kubeconfig)
    config_context = try(module.target-eks[0].cluster.arn, null)
  }
}
provider "aws" { 
  profile = var.target_aws_profile
  region = var.target_aws_region
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
  alias      = "attacker"
  profile    = var.attacker_lacework_profile
}
provider "lacework" {
  alias      = "target"
  profile    = var.target_lacework_profile
}
provider "restapi" {
  alias = "attacker"
  uri                  = "https://api.dynu.com"
  write_returns_object = true
  debug                = true
  id_attribute         = "id"
  timeout              = 600

  headers = {
    API-Key = var.attacker_dynu_api_key
    Content-Type = "application/json"
    accept = "application/json"
    Cache-Control =  "no-cache, no-store"
    User-Agent = "curl/8.4.0"
  }

  create_method  = "POST"
  update_method  = "POST"
  destroy_method = "DELETE"
}
provider "restapi" {
  alias = "target"
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true
  id_attribute         = "id"
  timeout              = 600

  headers = {
    API-Key = var.target_dynu_api_key
    Content-Type = "application/json"
    accept = "application/json"
    Cache-Control =  "no-cache, no-store"
    User-Agent = "curl/8.4.0"
  }

  create_method  = "POST"
  update_method  = "POST"
  destroy_method = "DELETE"
}