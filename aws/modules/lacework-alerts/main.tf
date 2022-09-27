locals {
  alert_channels = flatten(
    [
      length(lacework_alert_channel_slack.ops_alert) > 0 ? [lacework_alert_channel_slack.ops_alert[0].id] : [],
      length(lacework_alert_channel_jira_cloud.ops_alert) > 0 ? [lacework_alert_channel_jira_cloud.ops_alert[0].id] : []
    ]
  )
}

# resource "lacework_resource_group_aws" "prod_aws_account" {
#   name     = "Production AWS Resources"
#   accounts = ["xxxxxx"]
# }

resource "lacework_alert_channel_jira_cloud" "ops_alert" {
  count       = var.enable_jira_cloud_alerts == true ? 1 : 0
  name        = "jira_cloud_ops_alert"
  jira_url    = var.jira_cloud_url
  issue_type  = var.jira_cloud_issue_type
  project_key = var.jira_cloud_project_key
  username    = var.jira_cloud_username
  api_token   = var.jira_cloud_api_token
}
resource "lacework_alert_channel_slack" "ops_alert" {
  count       = var.enable_slack_alerts == true ? 1 : 0
  name      = "slack_ops_alert"
  slack_url = var.slack_token
}

resource "lacework_alert_rule" "prod" {
  count           = length(local.alert_channels) > 0 ? 1 : 0
  name            = "all_severities"
  severities      = [
    "Critical", 
    "High", 
    "Medium", 
    "Info", 
    "Low", 
    "Info"
  ]
  alert_channels  = local.alert_channels
  resource_groups = []
}