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
    default = "osconfig_deploy_docker_log4j_app"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "listen_port" {
  type = number
  description = "listening port for container"
  default=8000
}