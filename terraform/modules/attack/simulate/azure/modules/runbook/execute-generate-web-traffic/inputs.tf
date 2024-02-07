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
    default = "runbook_deploy_aws_cli"
}

variable "delay" {
  type = number
  description = "wait time between calling urls"
  default =  60
}

variable "urls" {
  type = list(string)
  description = "list of urls to connect to via curl"
  default =  []
}