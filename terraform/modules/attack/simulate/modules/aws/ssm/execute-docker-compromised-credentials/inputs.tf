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

variable "resource_query_exec_docker_compromised_keys_attacker" {
    type    = object({
      ResourceTypeFilters = list(string)
      TagFilters  = list(object({
        Key = string
        Values = list(string)
      }))
    })
    description = "JSON query to idenfity resources which will have lacework deployed"
    default = {
                ResourceTypeFilters = [
                    "AWS::EC2::Instance"
                ]

                TagFilters = [
                    {
                        Key = "ssm_exec_docker_compromised_keys_attacker"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
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

variable "wallet" {
  type = string
  description = "wallet for cloud crypto"
  default = ""
}

variable "minergate_user" {
  type = string
  description = "minergate user for host crypto"
  default = ""
}