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
                    osconfig_exec_vuln_npm_app_target = "true"
                }
}

variable "listen_port" {
  type = number
  description = "listening port for container"
  default=8000
}

variable "timeout" {
    type = string
    default = "600s"
}