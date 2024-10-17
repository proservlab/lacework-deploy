variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "gcp_location" {
    type = string
}

variable "gcp_project_id" {
    type    = string
}

variable "tag" {
    type = string
    default = "osconfig_exec_docker_cpuminer"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "minergate_image" {
    type = string
    description = "minergate docker image"
}
variable "minergate_name" {
    type = string
    description = "minergate docker name"
}

variable "minergate_server" {
    type = string
    description = "minergate server"
}

variable "minergate_user" {
    type = string
    description = "minergate user"
}

variable "attack_delay" {
    type = number
    default = "50400"
}