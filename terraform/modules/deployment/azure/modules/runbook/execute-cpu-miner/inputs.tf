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
    default = "runbook_exec_docker_cpuminer"
}

variable "minergate_server" {
    type = string
    description = "minergate server"
}

variable "minergate_user" {
    type = string
    description = "minergate user"
}

variable "xmrig_version" {
    type = string
    description = "xmrig version"
}

variable "attack_delay" {
    type = number
    description = 50400
}