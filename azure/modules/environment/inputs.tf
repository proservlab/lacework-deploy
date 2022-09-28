variable "environment" {
  description = "environment name"
  type        = string
}

variable "region" {
  description = "region name"
  type        = string
}

###########################
# Kubernetes Admission Controller
###########################

variable "cluster_name" {
  description = "the kubernetes cluster name to deploy to"
  type = string
}

variable "proxy_token" {
  description = "proxy scanner token"
}

variable "lacework_account_name" {
  description = "lacework account name"
}

###########################
# Slack Alerts
###########################

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

###########################
# Jira Alerts
###########################
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

###########################
# Azure Resources
###########################

variable "enable_compute" {
  description = "enable disable setup of compute instances (default 1 instance)"
  type = bool
  default = true
}

variable "enable_aks" {
  description = "enable disable aks setup (default 3 node cluster)"
  type = bool
  default = true
}

variable "enable_aks_app" {
  description = "enable disable of kubernetes simple app (default nginx - requires enable_eks)"
  type = bool
  default = false
}


###########################
# Lacework
###########################

variable "lacework_agent_access_token" {
  description = "preconfigured lacework agent access token"
  type = string
  default = "false"
}

variable "lacework_server_url" {
  description = "lacework server url"
  type = string
  default = "https://api.lacework.net"
}

variable "enable_lacework_audit_config" {
  description = "enable disable lacework audit and config"
  type = bool
  default = true
}

variable "enable_lacework_daemonset" {
  description = "enable disable of deployment of lacework daemonset (requires enable_eks)"
  type = bool
  default = false
}

variable "enable_lacework_daemonset_compliance" {
  description = "enable disable of deployment of lacework compliance agent (requires enable_eks)"
  type = bool
  default = false
}

variable "enable_lacework_alerts" {
  description = "enable disable of configuration of lacework alerts (default slack channel)"
  type = bool
  default = false
}

variable "enable_lacework_custom_policy"{
  description = "enable disable of configuration of lacework custom policy (default redteam alerts)"
  type = bool
  default = false
}

variable "enable_lacework_admissions_controller" {
  description = "enable disable of configuration of lacework agentless scanning"
  type = bool
  default = false
}

###########################
# Attack
###########################

variable "enable_attack_kubernetes_voteapp" {
  description = "enable disable of deployment of vulnerable voteapp to kubernetes"
  type = bool
  default = false
}

