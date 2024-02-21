variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "name" {
  type = string
  default = "main"
}

variable "role" {
  type = string
  default = "default"
}

variable "trust_security_group" {
  type = bool
  description = "Enable endpoints within the security group to communicate on all ports and protocols."
  default = false
}

variable "private_ingress_rules" {
  type    = list(map(any))
  default = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "allow ssh inbound"
      }
  ]
}

variable "private_egress_rules" {
  type    = list(map(any))
  default = [
      {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_block = "0.0.0.0/0"
          description = "allow all outbound"
      }
  ]
}

variable "private_app_ingress_rules" {
  type    = list(map(any))
  default = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "allow ssh inbound"
      }
  ]
}

variable "private_app_egress_rules" {
  type    = list(map(any))
  default = [
      {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_block = "0.0.0.0/0"
          description = "allow all outbound"
      }
  ]
}

variable "private_network" {
  type = string
  description = "network"
  default = "172.16.0.0/16"
}

variable "private_subnet" {
  type = string
  description = "subnet"
  default = "172.16.0.0/24"
}

variable "private_app_network" {
  type = string
  description = "app network"
  default = "172.17.0.0/16"
}

variable "private_app_subnet" {
  type = string
  description = "subnet"
  default = "172.17.0.0/24"
}

variable "private_nat_subnet" {
  type = string
  description = "private nat subnet"
  default = "172.16.10.0/24"
}

variable "service_account_email" {
    type = string
}