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

variable "public_resource_group" {
    type = any
    description = "public azure resource group for runbook from compute"
}

variable "public_automation_account" {
    type = string
    description = "automation account name"
}

variable "public_automation_princial_id"{
    type = string
    description = "automation account principal id"
}

variable "private_resource_group" {
    type = any
    description = "private azure resource group for runbook from compute"
}

variable "private_automation_account"{
    type = string
    description = "automation account name"
}

variable "private_automation_princial_id"{
    type = string
    description = "automation account principal id"
}

variable "tag" {
    type = string
    description = "tag associated with this runbook"
    default = "runbook_exec_reverse_shell_target"
}

variable "host_ip" {
  type = string
  description = "IP address of attacker"
}

variable "host_port" {
  type = number
  description = "Port address of attacker"
  default = 4444
}