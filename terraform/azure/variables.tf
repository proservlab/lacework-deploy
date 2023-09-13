##################################################
# SCENARIO
##################################################

variable "scenario" {
  type        = string
  description = "Scenario directory name"
  default     = "simple"
}

variable "scenarios_path" {
  type        = string
  description = "Path to the scenarios directory"
  default     = "../scenarios"
}

variable "deployment" {
  type        = string
  description = "Unique deployment id"
  default     = "00000001"
}

##################################################
# REGION
##################################################

variable "region" {
  description = "default aws region"
  default     = "us-east-1"
  type        = string
}

##################################################
# AWS
##################################################

variable "attacker_aws_profile" {
  type        = string
  description = "attacker aws profile"
  default     = null
}

variable "attacker_aws_region" {
  type        = string
  description = "attacker aws region"
  default     = "us-east-1"
}

variable "target_aws_profile" {
  type        = string
  description = "target aws profile"
  default     = null
}

variable "target_aws_region" {
  type        = string
  description = "target aws region"
  default     = "us-east-1"
}

##################################################
# GCP
##################################################

variable "attacker_gcp_project" {
  type        = string
  description = "attacker gcp project"
  default     = null
}

variable "attacker_gcp_region" {
  type        = string
  description = "attacker gcp region"
  default     = "us-central1"
}

variable "target_gcp_project" {
  type        = string
  description = "target gcp profile"
  default     = null
}

variable "target_gcp_region" {
  type        = string
  description = "target gcp region"
  default     = "us-central1"
}

variable "target_gcp_lacework_project" {
  type        = string
  description = "target gcp lacework profile"
  default     = null
}

variable "target_gcp_lacework_region" {
  type        = string
  description = "target gcp lacework region"
  default     = "us-central1"
}

variable "attacker_gcp_lacework_project" {
  type        = string
  description = "attacker gcp lacework profile"
  default     = null
}

variable "attacker_gcp_lacework_region" {
  type        = string
  description = "attacker gcp lacework region"
  default     = "us-central1"
}

##################################################
# AZURE
##################################################

variable "attacker_azure_subscription" {
  type        = string
  description = "attacker azure subscription"
  default     = null
}

variable "attacker_azure_tenant" {
  type        = string
  description = "attacker azure tenant"
  default     = null
}

variable "attacker_azure_region" {
  type        = string
  description = "attacker azure region"
  default     = "West US 2"
}

variable "target_azure_subscription" {
  type        = string
  description = "target azure subscription"
  default     = null
}

variable "target_azure_tenant" {
  type        = string
  description = "target azure tenant"
  default     = null
}

variable "target_azure_region" {
  type        = string
  description = "target azure region"
  default     = "West US 2"
}

##################################################
# LACEWORK
##################################################

variable "lacework_profile" {
  type        = string
  description = "lacework account profile name"
  default     = null
}

variable "lacework_account_name" {
  type        = string
  description = "lacework account name"
  default     = null
}

variable "lacework_server_url" {
  type        = string
  description = "lacework server url"
  default     = "https://agent.lacework.net"
}

variable "lacework_agent_access_token" {
  description = "lacework agent token"
  type        = string
  default     = null
}

variable "lacework_proxy_token" {
  type        = string
  description = "lacework proxy token used by the admissions controller"
  default     = null
}

variable "target_lacework_profile" {
  type        = string
  description = "lacework account profile name"
  default     = null
}

variable "target_lacework_account_name" {
  type        = string
  description = "lacework account name"
  default     = null
}

variable "target_lacework_server_url" {
  type        = string
  description = "lacework server url"
  default     = "https://agent.lacework.net"
}

variable "target_lacework_agent_access_token" {
  description = "lacework agent token"
  type        = string
  default     = null
}

variable "target_lacework_proxy_token" {
  type        = string
  description = "lacework proxy token used by the admissions controller"
  default     = null
}

variable "attacker_lacework_profile" {
  type        = string
  description = "lacework account profile name"
  default     = null
}

variable "attacker_lacework_account_name" {
  type        = string
  description = "lacework account name"
  default     = null
}

variable "attacker_lacework_server_url" {
  type        = string
  description = "lacework server url"
  default     = "https://agent.lacework.net"
}

variable "attacker_lacework_agent_access_token" {
  description = "lacework agent token"
  type        = string
  default     = null
}

variable "attacker_lacework_proxy_token" {
  type        = string
  description = "lacework proxy token used by the admissions controller"
  default     = null
}

##################################################
# SLACK
##################################################

variable "slack_token" {
  description = "slack webhook for critical alerts"
  type        = string
  default     = "false"
}

##################################################
# JIRA
##################################################

variable "jira_cloud_url" {
  description = "jira cloud url"
  type        = string
  default     = ""
}

variable "jira_cloud_project_key" {
  description = "jira cloud project key"
  type        = string
  default     = ""
}

variable "jira_cloud_issue_type" {
  description = "jira issue type"
  type        = string
  default     = ""
}

variable "jira_cloud_api_token" {
  description = "jira api token"
  type        = string
  default     = ""
}

variable "jira_cloud_username" {
  description = "jira username"
  type        = string
  default     = ""
}

##################################################
# KUBERNETES
##################################################

variable "attacker_cluster_name" {
  description = "attacker cluster name"
  type        = string
  default     = "attacker-cluster"
}

variable "target_cluster_name" {
  description = "target cluster name"
  type        = string
  default     = "target-cluster"
}

##################################################
# SIMULATION
##################################################

variable "attacker_context_config_protonvpn_user" {
  type        = string
  description = "protonvpn user"
  default     = ""
}

variable "attacker_context_config_protonvpn_privatekey" {
  type        = string
  description = "protonvpn privatekey"
  default     = ""
}

variable "attacker_context_config_protonvpn_password" {
  type        = string
  description = "protonvpn password"
  default     = ""
}

variable "attacker_context_config_protonvpn_tier" {
  type        = number
  description = "protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary)"
  default     = 0
}

variable "attacker_context_config_protonvpn_server" {
  type        = string
  description = "protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals"
  default     = "RANDOM"
}

variable "attacker_context_config_protonvpn_protocol" {
  type        = string
  description = "protonvpn protocol"
  default     = "udp"
}

variable "attacker_context_cloud_cryptomining_ethermine_wallet" {
  type        = string
  description = "cloud cryptomining ethermine wallet"
  default     = ""
}

variable "attacker_context_host_cryptomining_minergate_user" {
  type        = string
  description = "host cryptomining user"
  default     = ""
}

variable "attacker_context_host_cryptomining_nicehash_user" {
  type        = string
  description = "host cryptomining user"
  default     = ""
}

##################################################
# DYNU
##################################################

##################################################
# DYNU
##################################################

# dns hostname provisioning api key
variable "dynu_api_key" {
  type    = string
  default = ""
}

variable "dynu_dns_domain" {
  type    = string
  default = ""
}