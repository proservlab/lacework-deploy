# needed for attacker ecr
provider "aws" {
  alias   = "main"
  region  = var.aws_region
  profile = "proservlab"
}

provider "azuread" {
  alias = "main"
}

provider "azurerm" {
  alias = "main"
  features {}
}

provider "lacework" {
  alias   = "main"
  profile = var.lacework_profile
}

provider "kubernetes" {
  alias       = "main"
  config_path = "~/.kube/config"
}
provider "helm" {
  alias = "main"
  kubernetes {
    config_path = "~/.kube/config"
  }
}