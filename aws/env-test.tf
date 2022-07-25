locals {
  test_environment_name = "dev-test"
}

# example lacework aws config only (consolidated cloudtrail via controltower)
module "test-lacework-audit-config" {
  source      = "./modules/multi-lacework-audit-config"
  environment = local.test_environment_name
  providers = {
    aws      = aws.dev-test
    lacework = lacework.proservlab
  }
}

# module "dev-test" {
#   source       = "./modules/multi-eks"
#   aws_region   = var.region
#   environment  = local.test_environment_name
#   cluster-name = "${local.test_environment_name}-cluster"
#   providers = {
#     aws = aws.dev-test
#   }
# }

# resource "local_file" "test_kubeconfig" {
#   content  = module.dev-test.kubeconfig
#   filename = pathexpand("~/.kube/${module.dev-test.cluster_name}")
# }

# provider "kubernetes" {
#   alias                  = "dev-test"
#   host                   = module.dev-test.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.dev-test.cluster_ca_cert)
#   exec {
#     api_version = "client.authentication.k8s.io/v1alpha1"
#     args        = ["eks", "get-token", "--cluster-name", module.dev-test.cluster_name, "--profile", local.test_environment_name]
#     command     = "aws"
#   }
# }

# provider "helm" {
#   alias = "dev-test"
#   kubernetes {
#     host                   = module.dev-test.cluster_endpoint
#     cluster_ca_certificate = base64decode(module.dev-test.cluster_ca_cert)

#     exec {
#       api_version = "client.authentication.k8s.io/v1alpha1"
#       args        = ["eks", "get-token", "--cluster-name", module.tdev-est.cluster_name, "--profile", local.test_environment_name]
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
#     kubernetes = kubernetes.dev-test
#   }
# }

# # example lacework daemonset
# resource "lacework_agent_access_token" "dev-test" {
#   provider    = lacework.dev-test
#   name        = "lab-k8s-token-${local.test_environment_name}"
#   description = "k8s deployment for ${local.test_environment_name}"
# }

# module "test-lacework-daemonset" {
#   source                      = "./modules/multi-lacework-daemonset"
#   cluster-name                = "${local.test_environment_name}-cluster"
#   environment                 = local.test_environment_name
#   lacework_agent_access_token = lacework_agent_access_token.dev-test.token

#   providers = {
#     kubernetes = kubernetes.test
#     lacework   = lacework.dev-test
#     helm       = helm.dev-test
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