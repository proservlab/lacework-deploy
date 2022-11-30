variable "environment" {
  type    = string
}

variable "allow_all_inter_security_group" {
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

variable "instances" {
  type    = list(
    object({
      name            = string
      public          = bool
      instance_type   = string
      ami_name        = string
      enable_ssm      = bool
      ssm_deploy_tag  = map(any)
      tags            = map(any)
      user_data       = string
      user_data_base64 = string
    })
  )
  default = [
    { 
      name            = "ec2-private-1"
      public          = false
      instance_type   = "t2.micro"
      ami_name        = "ubuntu_focal"
      enable_ssm      = true
      ssm_deploy_tag  = { ssm_deploy_lacework = "true" }
      tags            = {}
      user_data       = null
      user_data_base64 = null
    },
    { 
      name            = "ec2-public-1"
      public          = true
      instance_type   = "t2.micro"
      ami_name        = "ubuntu_focal"
      enable_ssm      = true
      ssm_deploy_tag  = { ssm_deploy_lacework = "true" }
      tags            = {}
      user_data       = null
      user_data_base64 = null
    }
  ]
}

variable "public_network" {
  type = string
  description = "public network"
  default = "172.17.0.0/16"
}

variable "public_subnet" {
  type = string
  description = "public subnet"
  default = "172.17.0.0/24"
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