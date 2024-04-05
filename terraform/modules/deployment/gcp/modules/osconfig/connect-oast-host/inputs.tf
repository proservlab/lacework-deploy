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
    default = "osconfig_connect_oast_host"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "retry_delay_secs" {
  type = number
  description = "number of seconds before retrying the connection"
  default = 1800
}