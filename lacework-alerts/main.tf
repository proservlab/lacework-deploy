resource "lacework_resource_group_aws" "prod_aws_account" {
  name     = "Production AWS Resources"
  accounts = ["535849429554"]
}

resource "lacework_alert_channel_slack" "prod_ops_critical" {
  name      = "OPS Critical Alerts"
  slack_url = var.slack_prod_ops_critical
}

resource "lacework_alert_rule" "prod_aws" {
  name            = "Prod AWS Account Notification"
  severities      = ["Critical", "High"]
  alert_channels  = [lacework_alert_channel_slack.prod_ops_critical.id]
  resource_groups = [lacework_resource_group_aws.prod_aws_account.id]
}