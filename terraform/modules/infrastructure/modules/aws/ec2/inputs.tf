variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "trust_security_group" {
  type = bool
  description = "Enable endpoints within the security group to communicate on all ports and protocols."
  default = false
}

variable "public_ingress_rules" {
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

variable "public_egress_rules" {
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

variable "public_app_ingress_rules" {
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

variable "public_app_egress_rules" {
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

variable "instances" {
  sensitive   = false
  type    = list(
    object({
      name                            = string
      public                          = bool
      role                            = string
      instance_type                   = string
      ami_name                        = string
      tags                            = map(any)
      user_data                       = string
      user_data_base64                = string
    })
  )
  default = [
    { 
      name                            = "ec2-private-1"
      public                          = false
      role                            = "default"
      instance_type                   = "t2.micro"
      ami_name                        = "ubuntu_focal"
      tags                            = { }
      user_data                       = null
      user_data_base64                = null
    },
  ]
  validation {
    condition     = length([ for instance in var.instances: instance if contains(["app","default"],instance.role) ]) > 0
    error_message = "Role must be either 'app' or 'default'"
  }
}

variable "public_network" {
  type = string
  description = "public network"
  default = "172.18.0.0/16"
}

variable "public_subnet" {
  type = string
  description = "public subnet"
  default = "172.18.0.0/24"
}

variable "public_app_network" {
  type = string
  description = "public app network"
  default = "172.19.0.0/16"
}

variable "public_app_subnet" {
  type = string
  description = "public subnet"
  default = "172.19.0.0/24"
}

variable "private_network" {
  type = string
  description = "private network"
  default = "172.16.0.0/16"
}

variable "private_subnet" {
  type = string
  description = "private subnet"
  default = "172.16.100.0/24"
}

variable "private_nat_subnet" {
  type = string
  description = "private nat subnet"
  default = "172.16.10.0/24"
}

variable "private_app_network" {
  type = string
  description = "private network"
  default = "172.17.0.0/16"
}

variable "private_app_subnet" {
  type = string
  description = "private subnet"
  default = "172.17.100.0/24"
}

variable "private_app_nat_subnet" {
  type = string
  description = "private app nat subnet"
  default = "172.17.10.0/24"
}