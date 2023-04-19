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
    default = "osconfig_exec_port_forward_target"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "port_forwards" {
  type = list(object({
      src_port      = number
      dst_port      = number
      dst_ip        = string
      description   = string
    }))
  description = "list of port forwards"
}

variable "host_ip" {
  type = string
  description = "ip of the tunnel server"
}

variable "host_port" {
  type = number
  description = "port of the tunnel server"
  default = 8888
}