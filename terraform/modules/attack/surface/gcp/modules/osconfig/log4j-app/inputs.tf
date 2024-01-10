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
    default = "osconfig_exec_vuln_log4j_app_target"
}

variable "listen_port" {
  type = number
  description = "listening port for container"
  default=8080
}

variable "timeout" {
    type = string
    default = "600s"
}