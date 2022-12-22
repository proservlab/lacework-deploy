###########################
# ATTCKER PROVIDERS
###########################
provider "aws" {
  alias   = "attacker"
  region  = var.region
  profile = var.attacker_aws_profile
}

provider "lacework" {
  alias   = "attacker"
  profile = var.lacework_profile
}

provider "kubernetes" {
  alias       = "attacker"
  config_path = pathexpand("~/.kube/attacker-kubeconfig")
}

provider "helm" {
  alias = "attacker"
  kubernetes {
    config_path = pathexpand("~/.kube/attacker-kubeconfig")
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

provider "lacework" {
  alias   = "target"
  profile = var.lacework_profile
}

# resource "local_file" "target-kubeconfig" {
#   depends_on = [
#     module.target-infrastructure
#   ]
#   content  = ""
#   filename = pathexpand("~/.kube/target-kubeconfig")
# }

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