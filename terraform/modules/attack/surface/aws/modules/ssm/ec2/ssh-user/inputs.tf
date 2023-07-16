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
  default = "ssm_deploy_ssh_user"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}

variable "user" {
  type = any
  description = "user name to add to local system"
  default = "lou.caloozer"
}

variable "password" {
  type = string
  description = "password for new local user - default is random"
  default = null
}