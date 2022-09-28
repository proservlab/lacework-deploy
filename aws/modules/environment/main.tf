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

  depends_on = [
    module.eks
  ]
}

#########################
# Lacework
#########################
resource "kubernetes_namespace" "lacework" {
  count = var.enable_eks == true && (var.enable_lacework_admissions_controller || var.enable_lacework_daemonset) ? 1 : 0
  metadata {
    name = "lacework"
  }

  depends_on = [
    module.eks
  ]
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

locals {
  lacework_agent_access_token = "${var.lacework_agent_access_token == "false" ? lacework_agent_access_token.main[0].token : var.lacework_agent_access_token}"
}

module "lacework-ssm-deployment" {
  count = var.enable_lacework_ssm_deployment == true ? 1 : 0
  source       = "../lacework-ssm-deployment"
  environment  = var.environment
  lacework_agent_access_token = local.lacework_agent_access_token
  lacework_server_url         = var.lacework_server_url
}

module "lacework-daemonset" {
  count = var.enable_eks == true && var.enable_lacework_daemonset == true ? 1 : 0
  source                                = "../lacework-daemonset"
  cluster_name                          = var.cluster_name
  environment                           = var.environment
  lacework_agent_access_token           = local.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = var.enable_lacework_daemonset_compliance == true ? var.enable_lacework_daemonset_compliance : false
  lacework_cluster_agent_cluster_region = var.region

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

module "lacework-alerts" {
  count = var.enable_lacework_alerts == true ? 1 : 0
  source       = "../lacework-alerts"
  environment  = var.environment
  
  enable_slack_alerts       = var.enable_slack_alerts
  slack_token               = var.slack_token

  enable_jira_cloud_alerts  = var.enable_jira_cloud_alerts
  jira_cloud_url            = var.jira_cloud_url
  jira_cloud_project_key    = var.jira_cloud_project_key
  jira_cloud_api_token      = var.jira_cloud_api_token
  jira_cloud_issue_type     = var.jira_cloud_issue_type
  jira_cloud_username       = var.jira_cloud_username
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
    module.eks,
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

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

