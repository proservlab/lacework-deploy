variable "name" {
    type = string
    description = "name of the vpc"
}

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

variable "private_ingress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "allow ssh inbound"
        }
    ]
    description = <<-EOT
        example ingress rule: 
        [{
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "allow ssh inbound"
        }]
    EOT
}

variable "private_egress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = "0.0.0.0/0"
            description = "allow all outbound"
        }
    ]
    description = <<-EOT
        example egress rules: 
        [{
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = "0.0.0.0/0"
            description = "allow all outbound"
        }]
    EOT
}

variable "private_app_ingress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "allow ssh inbound"
        }
    ]
    description = <<-EOT
        example ingress rule: 
        [{
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "allow ssh inbound"
        }]
    EOT
}

variable "private_app_egress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = "0.0.0.0/0"
            description = "allow all outbound"
        }
    ]
    description = <<-EOT
        example egress rules: 
        [{
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = "0.0.0.0/0"
            description = "allow all outbound"
        }]
    EOT
}

variable "public_ingress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "allow ssh inbound"
        }
    ]
    description = <<-EOT
        example ingress rule: 
        [{
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "allow ssh inbound"
        }]
    EOT
}

variable "public_egress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = "0.0.0.0/0"
            description = "allow all outbound"
        }
    ]
    description = <<-EOT
        example egress rules: 
        [{
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = "0.0.0.0/0"
            description = "allow all outbound"
        }]
    EOT
}

variable "public_app_ingress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "allow ssh inbound"
        }
    ]
    description = <<-EOT
        example ingress rule: 
        [{
          from_port   = 22
          to_port     = 22
          protocol    = "tcp"
          cidr_block  = "0.0.0.0/0"
          description = "allow ssh inbound"
        }]
    EOT
}

variable "public_app_egress_rules" {
    type = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_block  = string
      description = string
    }))
    default     = [
        {
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = "0.0.0.0/0"
            description = "allow all outbound"
        }
    ]
    description = <<-EOT
        example egress rules: 
        [{
            from_port = 0
            to_port = 0
            protocol = "-1"
            cidr_block = "0.0.0.0/0"
            description = "allow all outbound"
        }]
    EOT
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
  description = "public network"
  default = "172.19.0.0/16"
}

variable "public_app_subnet" {
  type = string
  description = "public app subnet"
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
  description = "private nat subnet"
  default = "172.17.10.0/24"
}


variable "enable_public_vpc" {
  type = bool
  description = "enable/disable creation of public vpc"
  default = true
}

variable "enable_public_app_vpc" {
  type = bool
  description = "enable/disable creation of public app vpc"
  default = true
}

variable "enable_private_vpc" {
  type = bool
  description = "enable/disable creation of private vpc"
  default = true
}

variable "enable_private_app_vpc" {
  type = bool
  description = "enable/disable creation of private app vpc"
  default = true
}