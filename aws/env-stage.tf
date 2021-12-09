locals {
  stage_environment_name = "stage"
}

# module "stage" {
#   source       = "./modules/multi-eks"
#   aws_region   = var.region
#   environment  = local.stage_environment_name
#   cluster-name = "${local.stage_environment_name}-cluster"
#   providers = {
#     aws = aws.stage
#   }
# }

# resource "local_file" "stage_kubeconfig" {
#   content  = module.stage.kubeconfig
#   filename = pathexpand("~/.kube/${module.stage.cluster_name}")
# }

# provider "kubernetes" {
#   alias                  = "stage"
#   host                   = module.stage.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.stage.cluster_ca_cert)
#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     args        = ["eks", "get-token", "--cluster-name", module.stage.cluster_name, "--profile", local.stage_environment_name]
#     command     = "aws"
#   }
# }

# provider "helm" {
#   alias = "stage"
#   kubernetes {
#     host                   = module.stage.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.stage.cluster_ca_cert)

#     exec {
#       api_version = "client.authentication.k8s.io/v1alpha1"
#       args        = ["eks", "get-token", "--cluster-name", module.stage.cluster_name, "--profile", local.stage_environment_name]
#       command     = "aws"
#     }
#   }
# }

# # example of kubernetes configuration 
# # - ideally application lives in seperate project to allow for deployment outside of IaC
# # - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
# module "stage-kubenetes" {
#   source      = "./modules/multi-kubernetes"
#   aws_region  = var.region
#   environment = local.stage_environment_name

#   providers = {
#     kubernetes = kubernetes.stage
#   }
# }

# # example lacework daemonset
# resource "lacework_agent_access_token" "stage" {
#   provider    = lacework.stage
#   name        = "lab-k8s-token-${local.stage_environment_name}"
#   description = "k8s deployment for ${local.stage_environment_name}"
# }

# module "stage-lacework-daemonset" {
#   source                      = "./modules/multi-lacework-daemonset"
#   cluster-name                = "${local.stage_environment_name}-cluster"
#   environment                 = local.stage_environment_name
#   lacework_agent_access_token = lacework_agent_access_token.stage.token

#   providers = {
#     kubernetes = kubernetes.stage
#     lacework   = lacework.stage
#     helm       = helm.stage
#   }
# }

# #example lacework aws config and cloudtrail setup
# module "stage-lacework-audit" {
#   source      = "./modules/multi-lacework-audit"
#   environment = local.stage_environment_name
#   providers = {
#     aws      = aws.stage
#     lacework = lacework.stage
#   }
# }