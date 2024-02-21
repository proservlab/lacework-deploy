##################################################
# Context
##################################################

variable "target_infrastructure_config" {
  type = any
  description = "Schema defined in modules/context/infrastructure"
}
variable "target_surface_config" {
  type = any
  description = "Schema defined in modules/context/surface"
}
variable "target_simulate_config" {
  type = any
  description = "Schema defined in modules/context/simulate"
}
variable "target_aws_profile" {
  type = string
  description = "aws profile"

}
variable "target_aws_region" {
  type = string
  description = "aws region"

}
variable "target_kubeconfig" {
  type = string
  description = "kubeconfig path"
}
variable "target_lacework_profile" {
  type = string
  description = "lacework profile"
}
variable "target_lacework_account_name" {
  type = string
  description = "lacework account name"
}
variable "target_lacework_server_url" {
  type = string
  description = "lacework server url"
}
variable "target_lacework_agent_access_token" {
  type = string
  description = "lacework agent access token"
}
variable "target_lacework_proxy_token" {
  type = string
  description = "lacework proxy token"
}
variable "target_lacework_sysconfig_path" {
  type = string
  description = "lacework syscall config path"
}
variable "target_protonvpn_user" {
  type        = string
  description = "protonvpn user"
  default     = ""
}
variable "target_protonvpn_password" {
  type        = string
  description = "protonvpn password"
  default     = ""
}
variable "target_protonvpn_tier" {
  type        = number
  description = "protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary)"
  default     = 0
}
variable "target_protonvpn_server" {
  type        = string
  description = "protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals"
  default     = "RANDOM"
}
variable "target_protonvpn_protocol" {
  type        = string
  description = "protonvpn protocol"
  default     = "udp"
}