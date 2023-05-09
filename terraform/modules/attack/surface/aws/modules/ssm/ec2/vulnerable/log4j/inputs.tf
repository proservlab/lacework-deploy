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
  default = "ssm_exec_log4j_target"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}