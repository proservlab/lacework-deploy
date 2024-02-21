variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "tag" {
  type = string
  default = "ssm_exec_port_forward"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
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
