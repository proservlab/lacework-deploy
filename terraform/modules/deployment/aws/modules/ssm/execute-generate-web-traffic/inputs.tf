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
  default = "ssm_exec_generate_web_traffic"
}

variable "timeout" {
  type = number
  default = 600
}

variable "cron" {
  type = string
  default = "cron(*/30 * * * ? *)"
  
}

variable "delay" {
  type = number
  description = "wait time between calling urls"
  default =  60
}

variable "urls" {
  type = list(string)
  description = "list of urls to connect to via curl"
  default =  []
}