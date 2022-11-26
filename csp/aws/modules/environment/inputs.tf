variable "environment" {
  description = "environment name"
  type        = string
}

variable "region" {
  description = "region name"
  type        = string
}

variable "disable_all" {
  description   = "override disable of all modules"
  type          = bool
  default       = false
}

variable "enable_all" {
  description   = "override enable of all modules"
  type          = bool
  default       = false
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
  type = string
}

variable "lacework_account_name" {
  description = "lacework account name"
  type = string
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

variable "enable_eks_psp" {
  description = "enable disable of kubernetes pod security policy"
  type = bool
  default = false
}

variable "enable_inspector" {
  description = "enable disable aws inspector"
  type = bool
  default = false
}

variable "enable_deploy_docker" {
  description = "enable disable ssm deploy docker capability"
  type = bool
  default = false
}

variable "enable_deploy_git" {
  description = "enable disable ssm deploy git capability"
  type = bool
  default = false
}

variable "instances" {
  type    = list(
    object({
      name            = string
      public          = bool
      instance_type   = string
      ami_name        = string
      enable_ssm      = bool
      ssm_deploy_tag  = map(any)
      tags            = map(any)
      user_data       = string
      user_data_base64 = string
    })
  )
  default = [
    { 
      name            = "ec2-private-1"
      public          = false
      instance_type   = "t2.micro"
      ami_name        = "ubuntu_focal"
      enable_ssm      = true
      ssm_deploy_tag  = { ssm_deploy_lacework = "true" }
      tags            = {}
      user_data       = null
      user_data_base64 = null
    },
  ]
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

variable "enable_lacework_eks_audit" {
  description = "enable disable of configuration of lacework eks audit"
  type = bool
  default = false
}



###########################
# Vulnerable App
###########################

variable "enable_attack_kubernetes_voteapp" {
  description = "enable disable of deployment of vulnerable voteapp to kubernetes"
  type = bool
  default = false
}

variable "enable_attack_kubernetes_log4shell" {
  description = "enable disable of deployment of vulnerable log4shell container to kubernetes"
  type = bool
  default = false
}

variable "enable_attack_kubernetes_privileged_pod" {
  description = "enable disable of deployment of vulnerable privileged pod to kubernetes"
  type = bool
  default = false
}

variable "enable_attack_kubernetes_root_mount_fs_pod" {
  description = "enable disable of deployment of vulnerable root mount fs to kubernetes"
  type = bool
  default = false
}



###########################
# Attack Surface
###########################

variable "enable_attacksurface_agentless_secrets" {
  description = "enable disable deployment of ssh private and public keys via ssm for agentless detection."
  type = bool
  default = false
}

###########################
# Attacker
###########################

variable "enable_attacker_malware_eicar" {
  description = "enable disable deployment of eicar malware test file for detection."
  type = bool
  default = false
}

variable "enable_attacker_connect_badip" {
  description = "enable disable connect to badip"
  type = bool
  default = false
}

variable "enable_attacker_connect_enumerate_host" {
  description = "enable disable connect enumerate host"
  type = bool
  default = false
}

variable "enable_attacker_connect_oast_host" {
  description = "enable disable connect oast host"
  type = bool
  default = false
}

variable "enable_attacker_exec_codecov" {
  description = "enable disable exec codecov"
  type = bool
  default = false
}

variable "enable_attacker_exec_reverseshell" {
  description = "enable disable exec reverseshell"
  type = bool
  default = false
}

variable "attacker_exec_reverseshell_payload" {
  description = "the payload to send after reverse shell connection"
  type = string
  default =<<-EOT
  touch /tmp/pwned
  EOT
}

variable "attacker_exec_reverseshell_port" {
  description = "the payload to send after reverse shell connection"
  type = number
  default = 4444
}

variable "enable_attacker_exec_http_listener" {
  description = "enable disable exec http listener"
  type = bool
  default = false
}
variable "attacker_exec_http_port" {
  description = "the payload to send after reverse shell connection"
  type = number
  default = 8080
}

variable "enable_attacker_exec_docker_cpuminer" {
  description = "enable disable docker cpuminer"
  type = bool
  default = false
}

variable "enable_attacker_exec_docker_log4shell" {
  description = "enable disable docker log4shell"
  type = bool
  default = false
}

variable "enable_attacker_kubernetes_app_kali" {
  description = "enable disable kernetes kali pod"
  type = bool
  default = false
}







