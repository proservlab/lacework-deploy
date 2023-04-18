variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "lacework_agent_access_token" {
    type    = string
}

variable "lacework_server_url" {
    type    = string
    default = "https://api.lacework.net"
}

variable "tag" {
  type = string
  default = "ssm_deploy_lacework"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}