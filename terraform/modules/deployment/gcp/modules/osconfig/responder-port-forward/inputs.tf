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
    default = "osconfig_exec_responder_port_forward"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "listen_port" {
  type = number
  description = "listen port"
  default = 8888
}