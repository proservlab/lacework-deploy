variable "environment" {
    type = string
}

variable "region" {
    type = string
}

variable "namespace" {
    type = string
    default = "rdsapp"
}

variable "cluster_vpc_id" {
    type = string
    description = "VPC id for the cluster - used to lb security group"
}

variable "cluster_vpc_subnet" {
    type = string 
    description = "VPC subnet"
}

variable "cluster_sg_id" {
    type = string 
    description = "Security group for the cluster nodes"
}

variable "cluster_openid_connect_provider_arn" {
    type = string
    description = "OIDC  provider arn for cluster"
}

variable "cluster_openid_connect_provider_url" {
    type = string
    description = "OIDC provider url for cluster"
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