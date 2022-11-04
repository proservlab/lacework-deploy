
# needed for attacker ecr
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
  alias = "main"
  # config_path = "~/.kube/config"
  host                   = module.environment-proservlab.eks[0].cluster.endpoint
  cluster_ca_certificate = base64decode(module.environment-proservlab.eks[0].cluster.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", var.cluster_name, "--region", var.region]
    command     = "aws"
  }
}
provider "helm" {
  alias = "main"
  kubernetes {
    config_path = "~/.kube/config"
  }
}