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
  default = "ssm_deploy_secret_aws_creds"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}

variable "compromised_credentials" {
  type = any
  description = "credentials to use in compromised keys attack"
}

variable "compromised_keys_user" {
  type = string
  default = "adam.inistrator@interlacelabs"
}