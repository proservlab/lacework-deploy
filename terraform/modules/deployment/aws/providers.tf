data "local_file" "attacker_kubeconfig" {
  count = local.attacker_infrastructure_config.context.aws.eks.enabled ? 1 : 0
  filename = pathexpand(module.attacker-eks[0].kubeconfig_path)
}

data "local_file" "target_kubeconfig" {
  count = local.target_infrastructure_config.context.aws.eks.enabled ? 1 : 0
  filename = pathexpand(module.target-eks[0].kubeconfig_path)
}

provider "kubernetes" {
  alias = "attacker"
  config_path = local.attacker_infrastructure_config.context.aws.eks.enabled ? data.local_file.attacker_kubeconfig[0].filename : local.attacker_kubeconfig
}
provider "kubernetes" {
  alias = "target"
  config_path = local.target_infrastructure_config.context.aws.eks.enabled ? data.local_file.target_kubeconfig[0].filename : local.target_kubeconfig
}
provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = local.attacker_infrastructure_config.context.aws.eks.enabled ? data.local_file.attacker_kubeconfig[0].filename : local.attacker_kubeconfig
  }
}
provider "helm" {
  alias = "target"
  kubernetes {
    config_path = local.target_infrastructure_config.context.aws.eks.enabled ? data.local_file.target_kubeconfig[0].filename : local.target_kubeconfig
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