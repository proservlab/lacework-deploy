variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "cluster_name" {
    type = string
}

variable "cluster_resource_group" {
    type = any
}

variable "region" {
    type = string
    description = "azure region"
}

variable "authorized_ip_ranges" {
    type = list(string)
    default = ["0.0.0.0/0"]
}