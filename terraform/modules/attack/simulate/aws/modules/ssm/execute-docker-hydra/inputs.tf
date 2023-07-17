variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
  type    = string
}

variable "tag" {
  type = string
  default = "ssm_exec_docker_hydra"
}

variable "timeout" {
  type = number
  default = 3600
}

variable "cron" {
  type = string
  default = "cron(*/30 * * * ? *)"
}

variable "image" {
  type = string
  description = "docker image to use"
  default =  "ghcr.io/credibleforce/proxychains-hydra:main"
}

variable "container_name" {
  type = string
  description = "docker container name"
  default =  "hydra"
}

variable "use_tor" {
  type = bool
  description = "whether to use the tor network for scanning"
  default = false
}

variable "custom_user_list" {
  type = list(string)
  default = []
}

variable "custom_password_list" {
  type = list(string)
  default = []
}

variable "user_list" {
  type = string
  default = null
}

variable "password_list" {
  type = string
  default = null
}

variable "targets" {
  type = list(string)
  description = "target to use for brute force - default is local network"
  default = []
}

variable "ssh_user" {
  type = any
  description = "valid user credentials"
  default = null
}