locals {
  prod_environment_name = "dev-prod"
}

# example lacework aws config only (consolidated cloudtrail via controltower)
module "prod-lacework-audit-config" {
  source      = "./modules/multi-lacework-audit-config"
  environment = local.prod_environment_name
  providers = {
    aws      = aws.dev-prod
    lacework = lacework.proservlab
  }
}

# module "dev-prod" {
#   source       = "./modules/multi-eks"
#   aws_region   = var.region
#   environment  = local.prod_environment_name
#   cluster-name = "${local.prod_environment_name}-cluster"
#   providers = {
#     aws = aws.dev-prod
#   }
# }

# resource "local_file" "dev-prod_kubeconfig" {
#   content  = module.dev-prod.kubeconfig
#   filename = pathexpand("~/.kube/${module.dev-prod.cluster_name}")
# }

# provider "kubernetes" {
#   alias                  = "dev-prod"
#   host                   = module.dev-prod.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.dev-prod.cluster_ca_cert)
#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     args        = ["eks", "get-token", "--cluster-name", module.dev-prod.cluster_name, "--profile", local.prod_environment_name]
#     command     = "aws"
#   }
# }

# provider "helm" {
#   alias = "dev-prod"
#   kubernetes {
#     host                   = module.dev-prod.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.dev-prod.cluster_ca_cert)

#     exec {
#       api_version = "client.authentication.k8s.io/v1alpha1"
#       args        = ["eks", "get-token", "--cluster-name", module.dev-prod.cluster_name, "--profile", local.prod_environment_name]
#       command     = "aws"
#     }
#   }
# }

# # example of kubernetes configuration 
# # - ideally application lives in seperate project to allow for deployment outside of IaC
# # - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
# module "dev-prod-kubenetes" {
#   source      = "./modules/multi-kubernetes"
#   aws_region  = var.region
#   environment = local.prod_environment_name
#   providers = {
#     kubernetes = kubernetes.prod
#   }
# }

# # example lacework daemonset
# resource "lacework_agent_access_token" "dev-prod" {
#   provider    = lacework.dev-prod
#   name        = "lab-k8s-token-${local.prod_environment_name}"
#   description = "k8s deployment for ${local.prod_environment_name}"
# }

# module "dev-prod-lacework-daemonset" {
#   source                      = "./modules/multi-lacework-daemonset"
#   cluster-name                = "${local.prod_environment_name}-cluster"
#   environment                 = local.prod_environment_name
#   lacework_agent_access_token = lacework_agent_access_token.dev-prod.token

#   providers = {
#     kubernetes = kubernetes.dev-prod
#     lacework   = lacework.dev-prod
#     helm       = helm.dev-prod
#   }
# }

# # example lacework aws config and cloudtrail setup
# module "prod-lacework-audit" {
#   source      = "./modules/multi-lacework-audit"
#   environment = local.prod_environment_name
#   providers = {
#     aws      = aws.dev-prod
#     lacework = lacework.dev-prod
#   }
# }