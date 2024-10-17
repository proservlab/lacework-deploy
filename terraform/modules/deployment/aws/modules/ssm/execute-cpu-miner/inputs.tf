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
  default = "ssm_exec_docker_cpuminer"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
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
    description = 50400
}