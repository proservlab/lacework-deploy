provider "google" {
  project = local.default_infrastructure_config.context.global.environment
  region = local.default_infrastructure_config.context.gcp.region
}

provider "google" {
  alias = "attacker"
  project = local.attacker_infrastructure_config.context.global.environment
  region = local.attacker_infrastructure_config.context.gcp.region
}

provider "google" {
  alias = "target"
  project = local.target_infrastructure_config.context.global.environment
  region = local.target_infrastructure_config.context.gcp.region
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}