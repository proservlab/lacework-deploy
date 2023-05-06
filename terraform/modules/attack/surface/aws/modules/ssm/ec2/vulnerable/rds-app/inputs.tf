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
  default = "ssm_exec_vuln_rdsapp_target"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}

variable "listen_port" {
  type = number
  description = "listening port for container"
  default=8088
}

variable "db_host"{
    type = string
    description = "db host"
}

variable "db_name"{
    type = string
    description = "db name"
}

variable "db_user"{
    type = string
    description = "db user"
}

variable "db_password"{
    type = string
    description = "db password"
}

variable "db_port"{
    type = string
    description = "db port"
}

variable "db_region"{
    type = string
    description = "db region"
}