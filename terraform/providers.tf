###########################
# ATTACKER PROVIDERS
###########################
provider "aws" {
  alias   = "attacker"
  region  = var.region
  profile = var.attacker_aws_profile
}

provider "google" {
  alias   = "attacker"
  project = var.attacker_gcp_project
  region  = var.attacker_gcp_region
}

provider "lacework" {
  alias   = "attacker"
  profile = var.lacework_profile
}

provider "kubernetes" {
  alias       = "attacker"
  config_path = try(module.target-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")
}

provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = try(module.target-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")
  }
}

###########################
# TARGET PROVIDERS
###########################
provider "aws" {
  alias   = "target"
  region  = var.region
  profile = var.target_aws_profile
}

provider "google" {
  alias   = "target"
  project = var.target_gcp_project
  region  = var.target_gcp_region
}

provider "lacework" {
  alias   = "target"
  profile = var.lacework_profile
}

provider "kubernetes" {
  alias       = "target"
  config_path = try(module.target-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")
}

provider "helm" {
  alias = "target"
  kubernetes {
    config_path = try(module.target-infrastructure.eks[0].kubeconfig_path, "~/.kube/config")
  }
}