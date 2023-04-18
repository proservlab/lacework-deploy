variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable region {
  type  = string
}

variable "cluster_name" {
  type    = string
}

variable "cluster_version" {
  type    = string
  default = "1.24"
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

variable "kubeconfig_path" {
  type = string
  description = "kubeconfig path"
}
