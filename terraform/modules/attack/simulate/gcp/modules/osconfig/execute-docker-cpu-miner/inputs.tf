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

variable "label" {
    type = map(string)
    default =   {
                    osconfig_exec_docker_cpuminer = "true"
                }
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