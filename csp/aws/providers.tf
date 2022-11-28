###########################
# ATTCKER PROVIDERS
###########################
provider "aws" {
  alias   = "attacker"
  region  = var.region
  profile = "attacker"
}

provider "lacework" {
  alias   = "attacker"
  profile = var.lacework_profile
}

provider "kubernetes" {
  alias = "attacker"

  host                   = length(module.attacker.eks) > 0 ? module.attacker.eks[0].cluster.endpoint : null
  cluster_ca_certificate = length(module.attacker.eks) > 0 ? base64decode(module.attacker.eks[0].cluster.certificate_authority[0].data) : null
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", length(module.attacker.eks) > 0 ? module.attacker.eks[0].id : "", "--region", var.region]
    command     = "aws"
  }
}
provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = "~/.kube/config"
  }
}

###########################
# TARGET PROVIDERS
###########################
provider "aws" {
  alias   = "target"
  region  = var.region
  profile = "target"
}

provider "lacework" {
  alias   = "target"
  profile = var.lacework_profile
}

provider "kubernetes" {
  alias = "target"

  host                   = length(module.target.eks) > 0 ? module.target.eks[0].cluster.endpoint : null
  cluster_ca_certificate = length(module.target.eks) > 0 ? base64decode(module.target.eks[0].cluster.certificate_authority[0].data) : null
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", length(module.target.eks) > 0 ? module.target.eks[0].id : "", "--region", var.region]
    command     = "aws"
  }
}
provider "helm" {
  alias = "target"
  kubernetes {
    config_path = "~/.kube/config"
  }
}