variable "account_name" {
  default = "root"
}

variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
  default = "us-east-1"
}