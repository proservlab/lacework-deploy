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
    default = "runbook_exec_responder_http_listener"
}

variable "listen_ip" {
  type = string
  description = "IP address of attacker"
  default = "0.0.0.0"
}

variable "listen_port" {
  type = number
  description = "Port address of attacker"
  default = 8080
}