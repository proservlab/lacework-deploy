# example audit and config
module "lacework-audit-config" {
  count = var.enable_lacework_audit_config == true ? 1 : 0
  source      = "../lacework-audit-config"
  environment = var.environment
}

module "ec2" {
  count = var.enable_ec2 == true ? 1 : 0
  source       = "../ec2"
  environment  = var.environment
  instance-name = "${var.environment}-instance"
}

resource "lacework_agent_access_token" "main" {
  count = var.lacework_agent_access_token == "false" ? 1 : 0
  name        = "${var.environment}-token"
  description = "deployment for ${var.environment}"
}

locals {
  lacework_agent_access_token = "${var.lacework_agent_access_token == "false" ? lacework_agent_access_token.main[0].token : var.lacework_agent_access_token}"
}

module "lacework-ssm-deployment" {
  count = var.enable_lacework_ssm_deployment == true ? 1 : 0
  source       = "../lacework-ssm-deployment"
  environment  = var.environment
  lacework_agent_token = local.lacework_agent_access_token
}

module "eks" {
  count = var.enable_eks == true ? 1 : 0
  source       = "../eks"
  environment  = var.environment
  cluster_name = var.cluster_name
}

# resource "local_file" "kubeconfig" {
#   count = var.enable_eks == true ? 1 : 0
#   content  = module.eks.kubeconfig
#   filename = pathexpand("~/.kube/${module.eks.cluster_name}")
# }

# provider "kubernetes" {
#   alias                  = "main"
#   host                   = module.eks.cluster_endpoint
#   cluster_ca_certificate = base64decode(module.eks.cluster_ca_cert)

#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
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
#       api_version = "client.authentication.k8s.io/v1beta1"
#       args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--profile", var.environment]
#       command     = "aws"
#     }
#   }
# }

# example of kubernetes configuration 
# - ideally application lives in seperate project to allow for deployment outside of IaC
# - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
module "kubenetes" {
  count = var.enable_eks == true && var.enable_eks_app == true ? 1 : 0
  source      = "../kubernetes"
  environment = var.environment
}

module "lacework-daemonset" {
  count = var.enable_eks == true && var.enable_lacework_daemonset == true ? 1 : 0
  source                      = "../lacework-daemonset"
  cluster-name                = var.cluster_name
  environment                 = var.environment
  lacework_agent_access_token = local.lacework_agent_access_token
}

module "lacework-alerts" {
  count = var.enable_lacework_alerts == true ? 1 : 0
  source       = "../lacework-alerts"
  environment  = var.environment
  slack_token = var.slack_token
}

module "lacework-custom-policy" {
  count = var.enable_lacework_custom_policy == true ? 1 : 0
  source       = "../lacework-custom-policy"
  environment  = var.environment
}

module "lacework-admission-controller" {
  count = var.enable_lacework_admissions_controller == true ? 1 : 0
  source       = "../lacework-admission-controller"
  environment  = var.environment
  lacework_account_name = var.lacework_account_name
  proxy_token = var.proxy_token
}

module "lacework-agentless" {
  count = var.enable_lacework_agentless == true ? 1 : 0
  source      = "../lacework-agentless"
  environment = var.environment
}

