##################################################
# Context
################################################## 

variable "parent" {
  type = list(string)
  default = []
} 

variable "config" {
  type = any
  description = "Schema defined in modules/context/attack/surface"
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}

variable "default_gcp_project" {
  type = string
  description = "gcp project"
}
variable "default_gcp_region" {
  type = string
  description = "gcp region"
}
variable "attacker_gcp_project" {
  type = string
  description = "gcp project"
}
variable "attacker_gcp_region" {
  type = string
  description = "gcp region"
}
variable "target_gcp_project" {
  type = string
  description = "gcp project"
}
variable "target_gcp_region" {
  type = string
  description = "gcp region"
}
variable "default_kubeconfig" {
  type = string
  description = "kubeconfig path"
}
variable "attacker_kubeconfig" {
  type = string
  description = "kubeconfig path"
}
variable "target_kubeconfig" {
  type = string
  description = "kubeconfig path"
}
variable "default_lacework_profile" {
  type = string
  description = "lacework profile"
}
variable "default_lacework_account_name" {
  type = string
  description = "lacework account name"
}
variable "default_lacework_server_url" {
  type = string
  description = "lacework server url"
}
variable "default_lacework_agent_access_token" {
  type = string
  description = "lacework agent access token"
}
variable "default_lacework_proxy_token" {
  type = string
  description = "lacework proxy token"
}
variable "default_lacework_sysconfig_path" {
  type = string
  description = "lacework syscall config path"
}
variable "default_protonvpn_user" {
  type        = string
  description = "protonvpn user"
  default     = ""
}
variable "default_protonvpn_password" {
  type        = string
  description = "protonvpn password"
  default     = ""
}
variable "default_protonvpn_tier" {
  type        = number
  description = "protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary)"
  default     = 0
}
variable "default_protonvpn_server" {
  type        = string
  description = "protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals"
  default     = "RANDOM"
}
variable "default_protonvpn_protocol" {
  type        = string
  description = "protonvpn protocol"
  default     = "udp"
}