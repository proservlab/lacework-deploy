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
                    osconfig_exec_port_forward_attacker = "true"
                }
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