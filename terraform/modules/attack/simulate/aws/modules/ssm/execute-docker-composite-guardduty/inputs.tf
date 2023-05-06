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
  default = "ssm_exec_docker_guardduty_attacker"
}

variable "timeout" {
  type = number
  default = 5400
}

variable "cron" {
  type = string
  default = "cron(0 */2 * * ? *)"
}

variable "attack_delay" {
  type = number
  description = "wait time between baseline and attack (default: 12 hours)"
  default = 43200
}