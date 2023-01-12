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
  default = "us-east-1"
}

variable "enable_attacker" {
  type    = bool
  default = true
}

variable "enable_target" {
  type    = bool
  default = true
}

