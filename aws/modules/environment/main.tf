terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.12.1"
    }
    lacework = {
      source  = "lacework/lacework"
      version = "~> 0.22.1"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}


# example audit and config
module "lacework-audit-config" {
  source      = "../multi-lacework-audit-config"
  environment = var.environment
  providers = {
    aws      = aws
    lacework = lacework
  }
}

module "ec2" {
  source       = "../multi-ec2"
  aws_region   = var.region
  environment  = var.environment
  instance-name = "${var.environment}-instance"
  providers = {
    aws = aws
  }
}

# module "eks" {
#   source       = "../multi-eks"
#   aws_region   = var.region
#   environment  = var.environment
#   cluster-name = "${var.environment}-cluster"
#   providers = {
#     aws = aws
#   }
# }

# resource "local_file" "kubeconfig" {
#   content  = module.eks.kubeconfig
#   filename = pathexpand("~/.kube/${module.eks.cluster_name}")
# }

# provider "kubernetes" {
#   alias                  = "main"
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_ca_cert)

#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.environment]
#     command     = "aws"
#   }
# }

# provider "helm" {
#   alias = "main"
#   kubernetes {
#     host                   = module.eks.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.eks.cluster_ca_cert)

#     exec {
#       api_version = "client.authentication.k8s.io/v1alpha1"
#       args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.environment]
#       command     = "aws"
#     }
#   }
# }

# # example of kubernetes configuration 
# # - ideally application lives in seperate project to allow for deployment outside of IaC
# # - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
# module "proservlab-kubenetes" {
#   source      = "../multi-kubernetes"
#   aws_region  = var.region
#   environment = var.environment

#   providers = {
#     kubernetes = kubernetes.main
#   }
# }

# # example lacework daemonset
# resource "lacework_agent_access_token" "main" {
#   provider    = lacework
#   name        = "lab-k8s-token-${var.environment}"
#   description = "k8s deployment for ${var.environment}"
# }

# module "main-lacework-daemonset" {
#   source                      = "../multi-lacework-daemonset"
#   cluster-name                = "${var.environment}-cluster"
#   environment                 = var.environment
#   lacework_agent_access_token = lacework_agent_access_token.main.token

#   providers = {
#     kubernetes = kubernetes.main
#     lacework   = lacework
#     helm       = helm.main
#   }
# }