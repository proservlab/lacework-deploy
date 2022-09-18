# each profile definition here
provider "google" {
  alias   = "main"
  project = var.gcp_project
  region  = var.region
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
