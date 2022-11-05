variable "name" {
    type = string
    description = "name of the vpc"
}

variable "environment" {
    type = string
    description = "name of the environment"
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