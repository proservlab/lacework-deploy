locals{
  default_kubeconfig_path = pathexpand("~/.kube/gcp-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
  kubeconfig_path = try(module.gke[0].kubeconfig_path, local.default_kubeconfig_path)
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

provider "google" {
  project = var.default_gcp_project
  region = var.default_gcp_region
}

provider "google" {
  alias = "attacker"
  project = var.attacker_gcp_project
  region = var.attacker_gcp_region
}

provider "google" {
  alias = "target"
  project = var.target_gcp_project
  region = var.target_gcp_region
}

provider "lacework" {
  profile    = var.default_lacework_profile
}

provider "restapi" {
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = try(var.config.context.dynu_dns.api_token, ""),
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}