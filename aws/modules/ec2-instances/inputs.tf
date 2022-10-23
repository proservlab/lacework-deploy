variable "environment" {
  type    = string
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
    },
    { 
      name            = "ec2-public-2"
      public          = true
      instance_type   = "t2.micro"
      ami_name        = "ubuntu_focal"
      enable_ssm      = true
      ssm_deploy_tag  = { ssm_deploy_lacework = "false" }
      tags            = {}
      user_data       = null
      user_data_base64 = null
    }
  ]
}