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
    default = "runbook_deploy_secret_azure_credentials"
}

variable "compromised_credentials" {
  type = any
  description = "credentials to use in compromised keys attack"
}

variable "compromised_keys_user" {
  type = string
  default = "adam.inistrator@interlacelabs"
}