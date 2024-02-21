variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "security_group_id" {
    type = string
}

variable "trusted_attacker_source_enabled" {
  type = bool
  description = "Allow all tcp from attacker source public addresses inbound to the app load balancer(s)"
  default = true
}

variable "trusted_attacker_source" {
  type = list(string)
  description = "Allow all tcp from attacker source public addresses inbound to the app load balancer(s)"
  default = []
}

variable "trusted_target_source_enabled" {
  type = bool
  description = "Allow all tcp from attacker source public addresses inbound"
  default = true
}

variable "trusted_target_source" {
  type = list(string)
  description = "Allow all tcp from attacker source public addresses inbound"
  default = []
}

variable "trusted_workstation_source_enabled" {
  type = bool
  description = "Allow current workstation public address inbound"
  default = false
}

variable "trusted_workstation_source" {
  type = list(string)
  description = "Allow current workstation public address inbound"
  default = []
}

variable "additional_trusted_sources_enabled" {
  type = bool
  description = "List of additional trusted sources allowed inbound to the app load balancer(s)"
  default = false
}

variable "additional_trusted_sources" {
  type = list(string)
  description = "List of additional trusted sources allowed inbound to the app load balancer(s)"
  default = []
}

variable "trusted_tcp_ports" {
    type = object({
        from_port = number
        to_port = number
    })
}