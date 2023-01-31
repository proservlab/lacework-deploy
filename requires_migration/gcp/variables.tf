variable "aws_region" {
  description = "default aws region (used for attacker ecr and s3 backend)"
  default     = "us-east-1"
  type        = string
}

variable "region" {
  description = "default gcp region"
  default     = "us-central1"
  type        = string
}

variable "terraform_backend_bucket" {
  description = "terraform backend bucket name"
  type        = string
}

variable "terraform_backend_region" {
  description = "terraform backend region"
  type        = string
}
variable "terraform_backend_profile" {
  description = "terraform backend profile"
  type        = string
}
variable "terraform_backend_key" {
  description = "terraform backend key"
  type        = string
}
variable "terraform_backend_encrypt" {
  description = "terraform backend encrypt"
  type        = bool
}
variable "terraform_backend_dynamodb_table" {
  description = "terraform backend dynamodb table"
  type        = string
}

variable "gcp_project" {
  description = "name of the gcp project"
  type        = string
}

variable "gcp_location" {
  description = "default gcp location"
  default     = "us-central1-a"
  type        = string
}

variable "cluster_name" {
  description = "name of the eks cluster"
  default     = "terraform-cluster"
}

variable "lacework_profile" {
  description = "lacework account profile name"
  type        = string
}

variable "lacework_gcp_project" {
  description = "name of the gcp project"
  type        = string
}

variable "lacework_account_name" {
  description = "lacework account name"
}

variable "lacework_server_url" {
  description = "lacework server url"
  default     = "https://api.lacework.net"
}

##################################################
# Slack Alerts
##################################################

variable "enable_slack_alerts" {
  description = "enable or disable slack alerts"
  type        = bool
  default     = false
}

variable "slack_token" {
  description = "slack webhook for critical alerts"
  type        = string
  default     = "false"
}

##################################################
# Jira Alerts
##################################################
variable "enable_jira_cloud_alerts" {
  description = "enable or disable slack alerts"
  type        = bool
  default     = false
}

variable "jira_cloud_url" {
  description = "jira cloud url"
  type        = string
  default     = "false"
}

variable "jira_cloud_project_key" {
  description = "jira cloud project key"
  type        = string
  default     = "false"
}

variable "jira_cloud_issue_type" {
  description = "jira issue type"
  type        = string
  default     = "false"
}

variable "jira_cloud_api_token" {
  description = "jira api token"
  type        = string
  default     = "false"
}

variable "jira_cloud_username" {
  description = "jira username"
  type        = string
  default     = "false"
}

variable "lacework_agent_access_token" {
  description = "lacework agent token"
  type        = string
  default     = "false"
}

variable "lacework_proxy_token" {
  type        = string
  description = "proxy token used by the admissions controller"
}