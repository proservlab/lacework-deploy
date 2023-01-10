variable "environment" {
  type    = string
  default = "attacker"
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

