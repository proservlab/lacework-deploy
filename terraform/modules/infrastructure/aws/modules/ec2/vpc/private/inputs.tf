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

variable "role" {
    type = string
    description = "role for vpc (default or app)"
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