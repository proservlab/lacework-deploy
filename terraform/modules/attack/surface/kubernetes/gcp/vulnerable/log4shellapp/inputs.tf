variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "app" {
  default = "log4shell"
}

variable "app_namespace" {
  default = "log4shell"
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

variable "trusted_attacker_source" {
  type = list(string)
  description = "Allow all attacker source public addresses inbound to the app load balancer(s)"
  default = []
}

variable "trusted_workstation_source" {
  type = list(string)
  description = "Allow current workstation public address inbound to the app load balancer(s)"
  default = []
}

variable "additional_trusted_sources" {
  type = list(string)
  description = "List of additional trusted sources allowed inbound to the app load balancer(s)"
  default = []
}