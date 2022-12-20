###########################
# REGION
###########################

variable "region" {
  description = "default aws region"
  default     = "us-east-1"
  type        = string
}

###########################
# BACKEND
###########################
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

###########################
# LACEWORK
###########################

variable "lacework_profile" {
  type        = string
  description = "lacework account profile name"
}

variable "lacework_account_name" {
  type        = string
  description = "lacework account name"
}

variable "lacework_server_url" {
  type        = string
  description = "lacework server url"
  default     = "https://api.lacework.net"
}

variable "lacework_agent_access_token" {
  description = "lacework agent token"
  type        = string
  default     = "false"
}

variable "lacework_proxy_token" {
  type        = string
  description = "lacework proxy token used by the admissions controller"
  # default     = "false"
}

###########################
# SLACK
###########################

variable "slack_token" {
  description = "slack webhook for critical alerts"
  type        = string
  default     = "false"
}

###########################
# JIRA
###########################

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
# KUBERNETES
###########################

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

###########################
# SIMULATION
###########################

variable "attacker_context_config_protonvpn_user" {
  type        = string
  description = "protonvpn user"
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

variable "attacker_context_config_cryptomining_cloud_wallet" {
  type        = string
  description = "cloud cryptomining wallet"
  default     = ""
}

variable "attacker_context_config_cryptomining_host_user" {
  type        = string
  description = "host cryptomining user"
  default     = ""
}
