locals {
  config = var.config

  default_infrastructure_config = var.infrastructure.config[var.config.context.global.environment]
  attacker_infrastructure_config = var.infrastructure.config["attacker"]
  target_infrastructure_config = var.infrastructure.config["target"]
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../../general/workstation-external-ip"
}

##################################################
# Lacework
##################################################

# lacework alerts
module "lacework-alerts" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.alerts.enabled == true ) ? 1 : 0
  source       = "./modules/alerts"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  
  enable_slack_alerts       = local.config.context.lacework.alerts.slack.enabled
  slack_token               = local.config.context.lacework.alerts.slack.api_token

  enable_jira_cloud_alerts  = local.config.context.lacework.alerts.jira.enabled
  jira_cloud_url            = local.config.context.lacework.alerts.jira.cloud_url
  jira_cloud_project_key    = local.config.context.lacework.alerts.jira.cloud_project_key
  jira_cloud_api_token      = local.config.context.lacework.alerts.jira.cloud_api_token
  jira_cloud_issue_type     = local.config.context.lacework.alerts.jira.cloud_issue_type
  jira_cloud_username       = local.config.context.lacework.alerts.jira.cloud_username
}

# lacework custom policy
module "lacework-custom-policy" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.custom_policy.enabled == true ) ? 1 : 0
  source       = "./modules/custom-policy"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}