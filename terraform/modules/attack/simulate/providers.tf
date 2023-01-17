provider "kubernetes" {
  config_path = var.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = var.kubeconfig_path
  }
}

provider "aws" {
  alias = "attacker"
  profile = var.attacker_aws_profile
}

provider "aws" {
  alias = "target"
  profile = var.target_aws_profile
}