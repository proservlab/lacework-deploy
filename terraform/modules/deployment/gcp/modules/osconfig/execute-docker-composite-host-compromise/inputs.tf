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
    default = "osconfig_exec_docker_host_compromise"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "attack_delay" {
  type = number
  description = "wait time between baseline and attack (default: 12 hours)"
  default =  50400
}

