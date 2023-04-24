variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
  type    = string
}

variable "tag" {
  type = string
  default = "ssm_exec_docker_cloud_cryptomining_attacker"
}

variable "timeout" {
  type = number
  default = 5400
}

variable "cron" {
  type = string
  default = "cron(0 */2 * * ? *)"
}

variable "compromised_credentials" {
  type = any
  description = "credentials to use in compromised keys attack"
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

variable "protonvpn_privatekey" {
  type = string
  description = "protonvpn wireguard private key"
  default = ""
}

variable "ethermine_wallet" {
  type = string
  description = "ethermine wallet for cloud crypto"
  default = ""
}

variable "minergate_user" {
  type = string
  description = "minergate user for host crypto"
  default = ""
}

variable "nicehash_user" {
  type = string
  description = "nicehash user for host crypto"
  default = ""
}

variable "attack_delay" {
  type = number
  description = "wait time between baseline and attack (default: 12 hours)"
  default = 43200
}

variable "compromised_keys_user" {
  type = string
  default = "claude.kripto@interlacelabs"
}