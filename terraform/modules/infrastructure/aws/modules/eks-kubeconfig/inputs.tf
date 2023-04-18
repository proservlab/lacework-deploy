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

variable "aws_profile_name" {
  description = "aws profile name"
  type        = string
}

variable "kubeconfig_path" {
  type = string
  description = "kubeconfig path"
}