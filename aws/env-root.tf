locals {
  root_environment_name = "root"
}

# module "root" {
#   source       = "./modules/multi-eks"
#   aws_region   = var.region
#   environment  = local.root_environment_name
#   cluster-name = "${local.root_environment_name}-cluster"
#   providers = {
#     aws = aws.root
#   }
# }

# resource "local_file" "root_kubeconfig" {
#   content  = module.root.kubeconfig
#   filename = pathexpand("~/.kube/${module.root.cluster_name}")
# }

# provider "kubernetes" {
#   alias                  = "root"
#   host                   = module.root.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.root.cluster_ca_cert)

#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     args        = ["eks", "get-token", "--cluster-name", module.root.cluster_name, "--profile", local.root_environment_name]
#     command     = "aws"
#   }
# }

# provider "helm" {
#   alias = "root"
#   kubernetes {
#     host                   = module.root.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.root.cluster_ca_cert)

#     exec {
#       api_version = "client.authentication.k8s.io/v1alpha1"
#       args        = ["eks", "get-token", "--cluster-name", module.root.cluster_name, "--profile", local.root_environment_name]
#       command     = "aws"
#     }
#   }
# }

# # example of kubernetes configuration 
# # - ideally application lives in seperate project to allow for deployment outside of IaC
# # - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
# module "root-kubenetes" {
#   source      = "./modules/multi-kubernetes"
#   aws_region  = var.region
#   environment = local.root_environment_name

#   providers = {
#     kubernetes = kubernetes.root
#   }
# }

# # example lacework daemonset
# resource "lacework_agent_access_token" "root" {
#   provider    = lacework.root
#   name        = "lab-k8s-token-${local.root_environment_name}"
#   description = "k8s deployment for ${local.root_environment_name}"
# }

# module "root-lacework-daemonset" {
#   source                      = "./modules/multi-lacework-daemonset"
#   cluster-name                = "${local.root_environment_name}-cluster"
#   environment                 = local.root_environment_name
#   lacework_agent_access_token = lacework_agent_access_token.root.token

#   providers = {
#     kubernetes = kubernetes.root
#     lacework   = lacework.root
#     helm       = helm.root
#   }
# }

# # example lacework aws config and cloudtrail setup
# module "root-lacework-audit" {
#   source      = "./modules/multi-lacework-audit"
#   environment = local.root_environment_name
#   providers = {
#     aws      = aws.root
#     lacework = lacework.root
#   }
# }