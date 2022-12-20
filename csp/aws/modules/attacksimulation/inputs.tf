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

##########################
# Attacker Responders
##########################

variable "enable_attacker_responder_reverseshell" {
  description = "enable disable exec attacker reverseshell responder"
  type = bool
  default = false
}

variable "enable_attacker_responder_http" {
  description = "enable disable exec http listener"
  type = bool
  default = false
}

variable "enable_attacker_responder_port_forward" {
  description = "enable disable port forwarding on attackers"
  type = bool
  default = false
}

###########################
# Target Post Compromise Simulation
###########################

variable "enable_target_postcompromise_callhome_reverseshell" {
  description = "enable disable exec target reverseshell connect"
  type = bool
  default = false
}

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

variable "enable_target_postcompromise_docker_cpuminer" {
  description = "enable disable docker cpuminer"
  type = bool
  default = false
}

variable "enable_target_postcompromise_kubernetes_app_kali" {
  description = "enable disable kubernetes kali pod"
  type = bool
  default = false
}

variable "enable_target_postcompromise_port_forward" {
  description = "enable disable port forwarding on target"
  type = bool
  default = false
}

###########################
# Attack Simulation
###########################

variable "enable_attacker_compromise_docker_log4shell" {
  description = "enable disable docker log4shell"
  type = bool
  default = false
}

variable "enable_attacker_compromise_compromised_credentials" {
  description = "enable disable compromised credentials attack"
  type = bool
  default = false
}






