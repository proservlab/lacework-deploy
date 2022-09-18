#########################
# AWS 
#########################
module "ec2" {
  count = var.enable_ec2 == true ? 1 : 0
  source       = "../ec2"
  environment  = var.environment
  instance-name = "${var.environment}-instance"
}

module "eks" {
  count = var.enable_eks == true ? 1 : 0
  source       = "../eks"
  environment  = var.environment
  cluster_name = var.cluster_name
  region       = var.region
}


#########################
# Kubernetes
#########################

# example of kubernetes configuration 
# - ideally application lives in seperate project to allow for deployment outside of IaC
# - this configuration could be used to deploy any default setup like token hardening, default daemonsets, etc
module "kubernetes" {
  count = var.enable_eks == true && var.enable_eks_app == true ? 1 : 0
  source      = "../kubernetes"
  environment = var.environment
}

#########################
# Lacework
#########################
resource "kubernetes_namespace" "lacework" {
  count = var.enable_eks && (var.enable_lacework_admissions_controller || var.enable_lacework_daemonset) ? 1 : 0
  metadata {
    name = "lacework"
  }
}

module "lacework-audit-config" {
  count = var.enable_lacework_audit_config == true ? 1 : 0
  source      = "../lacework-audit-config"
  environment = var.environment
}

resource "lacework_agent_access_token" "main" {
  count = var.lacework_agent_access_token == "false" ? 1 : 0
  name        = "${var.environment}-token"
  description = "deployment for ${var.environment}"
}

module "lacework-ssm-deployment" {
  count = var.enable_lacework_ssm_deployment == true ? 1 : 0
  source       = "../lacework-ssm-deployment"
  environment  = var.environment
  lacework_agent_token = local.lacework_agent_access_token
}

module "lacework-daemonset" {
  count = var.enable_eks == true && var.enable_lacework_daemonset == true ? 1 : 0
  source                      = "../lacework-daemonset"
  cluster-name                = var.cluster_name
  environment                 = var.environment
  lacework_agent_access_token = local.lacework_agent_access_token

  depends_on = [
    kubernetes_namespace.lacework
  ]
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

  depends_on = [
    kubernetes_namespace.lacework
  ]
}

module "lacework-agentless" {
  count = var.enable_lacework_agentless == true ? 1 : 0
  source      = "../lacework-agentless"
  environment = var.environment
}


#########################
# Attack
#########################

module "attack-kubernetes-voteapp" {
  count = var.enable_attack_kubernetes_voteapp == true ? 1 : 0
  source      = "../attack-kubernetes-voteapp"
  environment = var.environment
  region      = var.region
}

