variable "environment" {
  type    = string
}

variable region {
  type  = string
}

variable "cluster_name" {
  type    = string
}

variable "aws_profile_name" {
  description = "aws profile name"
  type        = string
}

variable "public_access_cidr" {
  type        = list
  description = "public ip address cidr allowed to access kubernetes api (default: [ '0.0.0.0/0' ])"
  default     = [ "0.0.0.0/0" ]
}
