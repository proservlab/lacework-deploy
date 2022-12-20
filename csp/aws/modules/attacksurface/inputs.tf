variable "environment" {
  description = "environment name"
  type        = string
}

variable "region" {
  description = "region name"
  type        = string
}

variable "aws_profile_name" {
  description = "aws profile name"
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
# Kubernetes
###########################

variable "cluster_name" {
  description = "the kubernetes cluster name to deploy to"
  type = string
  default = "false"
}


###########################
# Attack Surface Kubernetes
###########################

variable "enable_target_attacksurface_kubernetes_voteapp" {
  description = "enable disable of deployment of vulnerable voteapp to kubernetes"
  type = bool
  default = false
}

variable "enable_target_attacksurface_kubernetes_log4shell" {
  description = "enable disable of deployment of vulnerable log4shell container to kubernetes"
  type = bool
  default = false
}

variable "enable_target_attacksurface_kubernetes_privileged_pod" {
  description = "enable disable of deployment of vulnerable privileged pod to kubernetes"
  type = bool
  default = false
}

variable "enable_target_attacksurface_kubernetes_root_mount_fs_pod" {
  description = "enable disable of deployment of vulnerable root mount fs to kubernetes"
  type = bool
  default = false
}



###########################
# Attack Surface Host
###########################

variable "enable_target_attacksurface_secrets_ssh" {
  description = "enable disable deployment of ssh private and public keys via ssm for agentless detection."
  type = bool
  default = false
}

variable "enable_target_attacksurface_docker_log4shell" {
  description = "enable disable docker log4shell"
  type = bool
  default = false
}

###########################
# Attacker Post Compromise Simulation
###########################

variable "enable_target_postcompromise_drop_malware_eicar" {
  description = "enable disable deployment of eicar malware test file for detection."
  type = bool
  default = false
}

variable "enable_target_postcompromise_callhome_malware_eicar" {
  description = "enable disable connect to badip"
  type = bool
  default = false
}

variable "enable_target_postcompromise_enumerate_host" {
  description = "enable disable connect enumerate host"
  type = bool
  default = false
}

variable "enable_target_postcompromise_callhome_oast_host" {
  description = "enable disable connect oast host"
  type = bool
  default = false
}

variable "enable_target_postcompromise_callhome_codecov" {
  description = "enable disable exec codecov"
  type = bool
  default = false
}

variable "enable_attacker_responder_reverseshell" {
  description = "enable disable exec attacker reverseshell listen"
  type = bool
  default = false
}

variable "enable_target_postcompromise_callhome_reverseshell" {
  description = "enable disable exec target reverseshell connect"
  type = bool
  default = false
}

variable "enable_attacker_responder_http" {
  description = "enable disable exec http listener"
  type = bool
  default = false
}

variable "enable_target_postcompromise_docker_cpuminer" {
  description = "enable disable docker cpuminer"
  type = bool
  default = false
}

variable "enable_target_attacksurface_docker_log4shell" {
  description = "enable disable docker log4shell"
  type = bool
  default = false
}

variable "enable_attacker_compromise_docker_log4shell" {
  description = "enable disable docker log4shell"
  type = bool
  default = false
}

variable "enable_target_postcompromise_kubernetes_app_kali" {
  description = "enable disable kernetes kali pod"
  type = bool
  default = false
}

variable "enable_target_postcompromise_port_forward" {
  description = "enable disable port forwarding on target"
  type = bool
  default = false
}

variable "enable_attacker_responder_port_forward" {
  description = "enable disable port forwarding on attackers"
  type = bool
  default = false
}

variable "enable_attacker_compromise_compromised_credentials" {
  description = "enable disable compromised credentials attack"
  type = bool
  default = false
}

# simulation attacker target
variable "target_context_credentials_compromised_aws" {
  type = any
  description = "credentials to use in compromised keys attack"
  default = {}
}

variable "attacker_context_config_protonvpn_user" {
  type = string
  description = "protonvpn user"
  default = ""
}

variable "attacker_context_config_protonvpn_password" {
  type = string
  description = "protonvpn password"
  default = ""
}

variable "attacker_context_config_protonvpn_tier" {
  type = number
  description = "protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary)"
  default = 0
}

variable "attacker_context_config_protonvpn_server" {
  type = string
  description = "protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals"
  default = "RANDOM"
}

variable "attacker_context_config_protonvpn_protocol" {
  type = string
  description = "protonvpn protocol"
  default = "udp"
}

variable "attacker_context_config_cryptomining_cloud_wallet" {
  type = string
  description = "cloud cryptomining wallet"
  default = ""
}

variable "attacker_context_config_cryptomining_host_user" {
  type = string
  description = "host cryptomining user"
  default = ""
}

variable "attacker_context_responder_http_port" {
  description = "http get/post capture server used for codecov"
  type = number
  default = 8444
}

variable "attacker_context_payload_reverseshell" {
  description = "the payload to send after reverse shell connection"
  type = string
  default = <<-EOT
  touch /tmp/pwned
  EOT
}

variable "attacker_context_responder_reverseshell_port" {
  description = "the payload to send after reverse shell connection"
  type = number
  default = 4444
}

variable "attacker_context_responder_log4shell_http_port" {
  description = "attacker http port used in codecov attack"
  type = number
  default = 8080
}
variable "attacker_context_responder_log4shell_ldap_port" {
  description = "attacker ldap port used in log4shell attack"
  type = number
  default = 1389
}

variable "target_context_listener_log4shell_http_port" {
  description = "attacker http port used in codecov attack"
  type = number
  default = 8080
}

variable "attacker_context_payload_log4shell" {
  type = string
  description = "bash payload to run on target"
  default = <<-EOT
    touch /tmp/log4shell_pwned
    EOT
}

variable "attacker_context_responder_portforward_server_port" {
  type = number
  description = "attacker port forward server port"
  default = 8888
}

variable "target_context_listener_portforward_ports" {
  type = list(object({
      src_port      = number
      dst_port      = number
      dst_ip        = string
      description   = string
    }))
  description = "list of ports forward through attacker port forward server"
  default = []
}

variable "attacker_context_instance_reverseshell" {
  type = list
  description = "attacker reverse shell instance details"
  default = []
}

variable "attacker_context_instance_reverseshell" {
  type = list
  description = "attacker http listener instance details"
  default = []
}

variable "attacker_context_instance_log4shell" {
  type = list
  description = "attacker log4shell instance details"
  default = []
}

variable "attacker_context_instance_portforward" {
  type = list
  description = "attacker port forward instance details"
  default = []
}

variable "target_context_instance_reverseshell" {
  type = list
  description = "target reveser shell instance details"
  default = []
}

variable "target_context_instance_log4shell" {
  type = list
  description = "target log4shell instance details"
  default = []
}

variable "target_context_instance_portforward" {
  type = list
  description = "target port forward instance details"
  default = []
}






