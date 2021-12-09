locals {
  test_environment_name = "test"
}

# module "test" {
#   source       = "./modules/multi-eks"
#   aws_region   = var.region
#   environment  = local.test_environment_name
#   cluster-name = "${local.test_environment_name}-cluster"
#   providers = {
#     aws = aws.test
#   }
# }

# resource "local_file" "test_kubeconfig" {
#   content  = module.test.kubeconfig
#   filename = pathexpand("~/.kube/${module.test.cluster_name}")
# }

# provider "kubernetes" {
#   alias                  = "test"
#   host                   = module.test.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.test.cluster_ca_cert)
#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     args        = ["eks", "get-token", "--cluster-name", module.test.cluster_name, "--profile", local.test_environment_name]
#     command     = "aws"
#   }
# }

# provider "helm" {
#   alias = "test"
#   kubernetes {
#     host                   = module.test.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.test.cluster_ca_cert)

#     exec {
#       api_version = "client.authentication.k8s.io/v1alpha1"
#       args        = ["eks", "get-token", "--cluster-name", module.test.cluster_name, "--profile", local.test_environment_name]
#       command     = "aws"
#     }
#   }
# }

# # example of kubernetes configuration 
# # - ideally application lives in seperate project to allow for deployment outside of IaC
# # - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
# module "test-kubenetes" {
#   source      = "./modules/multi-kubernetes"
#   aws_region  = var.region
#   environment = local.test_environment_name

#   providers = {
#     kubernetes = kubernetes.test
#   }
# }

# # example lacework daemonset
# resource "lacework_agent_access_token" "test" {
#   provider    = lacework.test
#   name        = "lab-k8s-token-${local.test_environment_name}"
#   description = "k8s deployment for ${local.test_environment_name}"
# }

# module "test-lacework-daemonset" {
#   source                      = "./modules/multi-lacework-daemonset"
#   cluster-name                = "${local.test_environment_name}-cluster"
#   environment                 = local.test_environment_name
#   lacework_agent_access_token = lacework_agent_access_token.test.token

#   providers = {
#     kubernetes = kubernetes.test
#     lacework   = lacework.test
#     helm       = helm.test
#   }
# }

# example lacework aws config and cloudtrail setup
# module "test-lacework-audit" {
#   source      = "./modules/multi-lacework-audit"
#   environment = local.test_environment_name
#   providers = {
#     aws      = aws.test
#     lacework = lacework.test
#   }
# }