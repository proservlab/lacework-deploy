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

variable "private_tag" {
    type = string
    description = "tag associated with this runbook"
    default = "runbook_deploy_secret_ssh_private"
}

variable "public_tag" {
    type = string
    description = "tag associated with this runbook"
    default = "runbook_deploy_secret_ssh_public"
}

variable "ssh_public_key_path" {
    type = string
    description = "path to write ssh public key"
    default = "/home/sshuser/.ssh/secret_key.pub"
}

variable "ssh_private_key_path" {
    type = string
    description = "path to write ssh private key"
    default = "/home/sshuser/.ssh/secret_key"
}

variable "ssh_authorized_keys_path" {
    type = string
    description = "path to append ssh authorized key"
    default = "/home/sshuser/.ssh/authorized_keys"
}
