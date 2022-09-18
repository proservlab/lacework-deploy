# each profile definition here
provider "aws" {
  alias   = "main"
  region  = var.region
  profile = "proservlab"
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