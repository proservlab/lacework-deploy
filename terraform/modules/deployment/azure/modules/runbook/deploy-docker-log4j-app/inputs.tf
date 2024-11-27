variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
    type = string
    description = "azure region"
}

variable "resource_group" {
  description = "resource group"
  type = any
}

variable "automation_account" {
    type = string
    description = "automation account name"
}

variable "automation_princial_id"{
    type = string
    description = "automation account principal id"
}

variable "tag" {
    type = string
    description = "tag associated with this runbook"
    default = "runbook_exec_docker_exploit_log4j_app"
}

variable "listen_port" {
  type = number
  description = "Port address of attacker"
  default = 8080
}

variable "trusted_addresses" {
  type = list(string)
  description = "list of trusted addresses of attacker server"
  default = []
}
