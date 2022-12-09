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
  alias       = "attacker"
  config_path = "~/.kube/config"
  #config_context = length(module.attacker.eks) > 0 ? "${module.attacker.eks[0].cluster_name}-${var.region}" : null
}

provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = "~/.kube/config"
    #config_context = length(module.attacker.eks) > 0 ? "${module.attacker.eks[0].cluster_name}-${var.region}" : null
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

  config_path = "~/.kube/config"
  #config_context = length(module.target.eks) > 0 ? "${module.target.eks[0].cluster_name}-${var.region}" : null
}

provider "helm" {
  alias = "target"
  kubernetes {
    config_path = "~/.kube/config"
    #config_context = length(module.target.eks) > 0 ? "${module.target.eks[0].cluster_name}-${var.region}" : null
  }
}