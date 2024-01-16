
variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
    type = string
    description = "azure region"
}

variable "resource_group" {
  description = "resource group"
  type = any
}

variable "automation_account" {
    type = string
    description = "automation account name"
}

variable "automation_princial_id"{
    type = string
    description = "automation account principal id"
}

variable "tag" {
    type = string
    description = "tag associated with this runbook"
    default = "runbook_exec_exploit_python3_twisted_app"
}

variable "protonvpn_user" {
  type = string
  description = "protonvpn user"
}

variable "protonvpn_password" {
  type = string
  description = "protonvpn password"
}

variable "protonvpn_tier" {
  type = number
  description = "protonvpn tier (0=free, 1=basic, 2=pro, 3=visionary)"
  default = 0
}

variable "protonvpn_server" {
  type = string
  description = "protonvpn server (RANDOM, AU, CR, IS, JP, JP-FREE, LV, NL, NL-FREE, NZ, SG, SK, US, US-NJ, US-FREE,...); see https://api.protonmail.ch/vpn/logicals"
  default = "RANDOM"
}

variable "protonvpn_protocol" {
  type = string
  description = "protonvpn protocol"
  default = "udp"
}