##################################################
# Context
##################################################

variable "attacker_infrastructure_config" {
  type = any
  description = "Schema defined in modules/context/infrastructure"
}
variable "attacker_attacksurface_config" {
  type = any
  description = "Schema defined in modules/context/surface"
}
variable "attacker_attacksimulate_config" {
  type = any
  description = "Schema defined in modules/context/simulate"
}
variable "attacker_aws_profile" {
  type = string
  description = "aws profile"

}
variable "attacker_aws_region" {
  type = string
  description = "aws region"

}
variable "attacker_kubeconfig" {
  type = string
  description = "kubeconfig path"
}
variable "attacker_lacework_profile" {
  type = string
  description = "lacework profile"
}
variable "attacker_lacework_account_name" {
  type = string
  description = "lacework account name"
}
variable "attacker_lacework_server_url" {
  type = string
  description = "lacework server url"
}
variable "attacker_lacework_agent_access_token" {
  type = string
  description = "lacework agent access token"
}
variable "attacker_lacework_proxy_token" {
  type = string
  description = "lacework proxy token"
}
variable "attacker_lacework_sysconfig_path" {
  type = string
  description = "lacework syscall config path"
}
variable "attacker_protonvpn_user" {
  type        = string
  description = "protonvpn user"
  default     = ""
}
variable "attacker_protonvpn_password" {
  type        = string
  description = "protonvpn password"
  default     = ""
}
variable "attacker_protonvpn_tier" {
  type        = number
  description = "protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary)"
  default     = 0
}
variable "attacker_protonvpn_server" {
  type        = string
  description = "protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals"
  default     = "RANDOM"
}
variable "attacker_protonvpn_protocol" {
  type        = string
  description = "protonvpn protocol"
  default     = "udp"
}
variable "attacker_dynu_api_key" {
  type = string
  description = "dynu dns api key"
  default = null
}
variable "attacker_dynu_dns_domain " {
  type = string
  description = "dynu dns domain"
  default = null
}