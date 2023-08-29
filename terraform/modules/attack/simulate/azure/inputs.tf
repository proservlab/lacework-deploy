##################################################
# Context
##################################################

variable "config" {
  type = any
  description = "Schema defined in modules/context/attack/simulate"
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}

variable "compromised_credentials" {
  type = any
}

variable "resource_group" {
  type = any
}

variable "target_resource_group" {
  type = any
}

variable "attacker_resource_group" {
  type = any
}

variable "parent" {
  type = list(string)
  default = []
} 

variable "default_azure_subscription" {
  type = string
  description = "azure subscription"
}
variable "default_azure_tenant" {
  type = string
  description = "azure tenant"
}
variable "default_azure_region"{
  type = string
  description = "azure profile"
}
variable "attacker_azure_subscription" {
  type = string
  description = "azure subscription"
}
variable "attacker_azure_tenant" {
  type = string
  description = "azure tenant"
}
variable "attacker_azure_region"{
  type = string
  description = "azure profile"
}
variable "target_azure_subscription" {
  type = string
  description = "azure subscription"
}
variable "target_azure_tenant" {
  type = string
  description = "azure tenant"
}
variable "target_azure_region"{
  type = string
  description = "azure profile"
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
variable "default_lacework_region" {
  type = string
  description = "lacework aws region"
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