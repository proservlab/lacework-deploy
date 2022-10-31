#########################
# AWS 
#########################
module "compute" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_compute == true ) ? 1 : 0
  source        = "../compute"
  environment   = var.environment
  region      = var.region
  instance-name = "${var.environment}-instance"
}

module "aks" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_aks == true ) ? 1 : 0
  source       = "../aks"
  environment  = var.environment
  cluster_name = var.cluster_name
  region       = var.region
}


#########################
# Kubernetes
#########################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_aks == true && var.enable_aks_app == true ) ? 1 : 0
  source      = "../kubernetes-app"
  environment = var.environment

  depends_on = [
    module.aks
  ]
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_aks == true && var.enable_aks_psp == true ) ? 1 : 0
  source      = "../kubernetes-psp"
  environment = var.environment

  depends_on = [
    module.aks
  ]
}

#########################
# Lacework
#########################
resource "kubernetes_namespace" "lacework" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_aks == true && (var.enable_lacework_admissions_controller || var.enable_lacework_daemonset) ) ? 1 : 0
  metadata {
    name = "lacework"
  }

  depends_on = [
    module.aks
  ]
}

module "lacework-audit-config" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_audit_config == true ) ? 1 : 0
  source      = "../lacework-audit-config"
  environment = var.environment
}

resource "lacework_agent_access_token" "main" {
  count = (var.enable_all == true) || (var.disable_all != true && var.lacework_agent_access_token == "false" ) ? 1 : 0
  name        = "${var.environment}-token"
  description = "deployment for ${var.environment}"
}

locals {
  lacework_agent_access_token = "${var.lacework_agent_access_token == "false" ? lacework_agent_access_token.main[0].token : var.lacework_agent_access_token}"
}

module "lacework-daemonset" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_aks == true && var.enable_lacework_daemonset == true ) ? 1 : 0
  source                      = "../lacework-daemonset"
  cluster-name                = var.cluster_name
  environment                 = var.environment
  lacework_agent_access_token = local.lacework_agent_access_token
  lacework_server_url         = var.lacework_server_url

  # compliance cluster agent
  lacework_cluster_agent_enable         = var.enable_lacework_daemonset_compliance == true ? var.enable_lacework_daemonset_compliance : false
  lacework_cluster_agent_cluster_region = var.region

  depends_on = [
    module.aks,
    kubernetes_namespace.lacework
  ]
}

module "lacework-alerts" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_alerts == true ) ? 1 : 0
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
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_lacework_custom_policy == true ) ? 1 : 0
  source       = "../lacework-custom-policy"
  environment  = var.environment
}

module "lacework-admission-controller" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_aks == true && var.enable_lacework_admissions_controller == true ) ? 1 : 0
  source       = "../lacework-admission-controller"
  environment  = var.environment
  lacework_account_name = var.lacework_account_name
  proxy_token = var.proxy_token

  depends_on = [
    module.aks,
    kubernetes_namespace.lacework
  ]
}


#########################
# Attack
#########################

module "attack-kubernetes-voteapp" {
  count = (var.enable_all == true) || (var.disable_all != true && var.enable_aks == true && var.enable_attack_kubernetes_voteapp == true ) ? 1 : 0
  source      = "../vulnerable-app-voteapp"
  environment = var.environment
  region      = var.region

  depends_on = [
    module.aks,
    kubernetes_namespace.lacework
  ]
}

