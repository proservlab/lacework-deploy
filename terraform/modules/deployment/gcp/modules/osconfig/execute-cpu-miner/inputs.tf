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
    default = "osconfig_exec_cpuminer"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "minergate_server" {
    type = string
    description = "minergate server"
}

variable "minergate_user" {
    type = string
    description = "minergate user"
}

variable "xmrig_version" {
    type = string
    description = "xmrig version"
}

variable "attack_delay" {
    type = number
    default = "50400"
}