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
  default = "ssm_exec_generate_aws_cli_traffic"
}

variable "timeout" {
  type = number
  default = 600
}

variable "cron" {
  type = string
  default = "cron(*/30 * * * ? *)"
  
}

variable "compromised_credentials" {
  type = any
  description = "credentials to use in compromised keys attack"
}

variable "compromised_keys_user" {
  type = string
  default = "khon.traktour@interlacelabs"
}

variable "commands" {
  type = list(string)
  description = "list of aws cli commands to run"
  default = ["aws sts get-caller-identity"]
}