locals {
  proservlab_environment_name = "proservlab"
}

# example lacework aws config only (consolidated cloudtrail via controltower)
module "root-lacework-audit-config" {
  source      = "./modules/multi-lacework-audit-config"
  environment = local.proservlab_environment_name
  providers = {
    aws      = aws.proservlab
    lacework = lacework.proservlab
  }
}

# module "proservlab" {
#   source       = "./modules/multi-eks"
#   aws_region   = var.region
#   environment  = local.proservlab_environment_name
#   cluster-name = "${local.proservlab_environment_name}-cluster"
#   providers = {
#     aws = aws.proservlab
#   }
# }

# resource "local_file" "proservlab_kubeconfig" {
#   content  = module.proservlab.kubeconfig
#   filename = pathexpand("~/.kube/${module.proservlab.cluster_name}")
# }

# provider "kubernetes" {
#   alias                  = "proservlab"
#   host                   = module.proservlab.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.proservlab.cluster_ca_cert)

#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     args        = ["eks", "get-token", "--cluster-name", module.proservlab.cluster_name, "--profile", local.proservlab_environment_name]
#     command     = "aws"
#   }
# }

# provider "helm" {
#   alias = "proservlab"
#   kubernetes {
#     host                   = module.proservlab.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.proservlab.cluster_ca_cert)

#     exec {
#       api_version = "client.authentication.k8s.io/v1alpha1"
#       args        = ["eks", "get-token", "--cluster-name", module.proservlab.cluster_name, "--profile", local.proservlab_environment_name]
#       command     = "aws"
#     }
#   }
# }

# # example of kubernetes configuration 
# # - ideally application lives in seperate project to allow for deployment outside of IaC
# # - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
# module "proservlab-kubenetes" {
#   source      = "./modules/multi-kubernetes"
#   aws_region  = var.region
#   environment = local.proservlab_environment_name

#   providers = {
#     kubernetes = kubernetes.proservlab
#   }
# }

# # example lacework daemonset
# resource "lacework_agent_access_token" "proservlab" {
#   provider    = lacework.proservlab
#   name        = "lab-k8s-token-${local.proservlab_environment_name}"
#   description = "k8s deployment for ${local.proservlab_environment_name}"
# }

# module "proservlab-lacework-daemonset" {
#   source                      = "./modules/multi-lacework-daemonset"
#   cluster-name                = "${local.proservlab_environment_name}-cluster"
#   environment                 = local.proservlab_environment_name
#   lacework_agent_access_token = lacework_agent_access_token.proservlab.token

#   providers = {
#     kubernetes = kubernetes.proservlab
#     lacework   = lacework.proservlab
#     helm       = helm.proservlab
#   }
# }

# # example lacework aws config and cloudtrail setup
# module "proservlab-lacework-audit" {
#   source      = "./modules/multi-lacework-audit"
#   environment = local.proservlab_environment_name
#   providers = {
#     aws      = aws.proservlab
#     lacework = lacework.proservlab
#   }
# }