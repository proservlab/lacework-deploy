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
# Slack
###########################

variable "slack_token" {
  description = "slack channel token for alerting"
  default = false
}

###########################
# AWS Resources
###########################

variable "enable_ec2" {
  description = "enable disable setup of ec2 instances (default 2 one with ssm role, one not)"
  type = bool
  default = true
}

variable "enable_eks" {
  description = "enable disable eks setup (default 3 node cluster t3a.small)"
  type = bool
  default = true
}

variable "enable_eks_app" {
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

variable "enable_lacework_ssm_deployment" {
  description = "enable disable lacework ssm deployment"
  type = bool
  default = false
}

variable "enable_lacework_daemonset" {
  description = "enable disable of deployment of lacework daemonset (requires enable_eks)"
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

variable "enable_lacework_agentless" {
  description = "enable disable of configuration of lacework agentless scanning"
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

