variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "app" {
  default = "nginx"
}

variable "app_namespace" {
  default = "default"
}

variable "cluster_vpc_id" {
  type = string
  description = "VPC id for the cluster - used to lb security group"
}

variable "service_port" {
  type = number
  description = "External port to expose result service on"
  default = 8080
}

variable "container_port" {
  type = number
  description = "Internal container port"
  default = 8080
}

variable "trusted_target_source_enabled" {
  type = bool
  description = "Allow all target source public addresses inbound to the app load balancer(s)"
  default = false
}

variable "trusted_target_source" {
  type = list(string)
  description = "Allow all target source public addresses inbound to the app load balancer(s)"
  default = []
}

variable "trusted_attacker_source_enabled" {
  type = bool
  description = "Allow all attacker source public addresses inbound to the app load balancer(s)"
  default = false
}

variable "trusted_attacker_source" {
  type = list(string)
  description = "Allow all attacker source public addresses inbound to the app load balancer(s)"
  default = []
}

variable "trusted_workstation_source_enabled" {
  type = bool
  description = "Allow current workstation public address inbound to the app load balancer(s)"
  default = false
}

variable "trusted_workstation_source" {
  type = list(string)
  description = "Allow current workstation public address inbound to the app load balancer(s)"
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

variable "privileged" {
    type = bool
    default = false
}

variable "image" {
  type = string
  default = "nginx:latest"
}

variable "command" {
  type = list(string)
  default = ["tail"]
}

variable "args" {
  type = list(string)
  default = ["-f", "/dev/null"]
}

variable "enable_dynu_dns" {
  type = bool
  default = false
}

variable "dynu_dns_domain" {
  type = string
  description = "The hostname you want to update"
  default = ""
}

variable "dynu_dns_domain_id" {
  type = string
  description = "The domain id for dynu hostname you want to update"
  default = ""
}