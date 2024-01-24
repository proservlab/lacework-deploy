variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "cluster_name" {
    type    = string
}

variable "cluster_version" {
  type    = string
  default = "1.28"
}

variable "cluster_endpoint" {
    type    = string
}

variable "cluster_ca_cert" {
    type    = string
}

variable "cluster_node_role_arn" {
    type = string
}

variable "cluster_subnet" {
    type = any
}

variable "cluster_sg" {
    type = string
}