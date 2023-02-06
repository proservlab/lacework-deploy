##################################################
# Context
##################################################

variable "config" {
  type = any
  description = "Schema defined in modules/context/infrastructure"
}

variable "dynu_api_token" {
    type = string
}

variable "dynu_dns_domain" {
    type = string
}