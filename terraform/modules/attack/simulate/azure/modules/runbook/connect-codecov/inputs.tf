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
    default = "runbook_connect_codecov"
}

variable "host_ip" {
  type = string
  description = "IP address of attacker"
}

variable "host_port" {
  type = number
  description = "Port address of attacker"
  default = 8080
}

variable "use_ssl" {
  type = bool
  description = "Enable disable use to HTTPS"
  default = false
}

variable "git_origin" {
  type = string
  description = "git origin to add to posted payload"
  default="git@git.localhost:repo/repo.git"
}

variable "env_secrets" {
  type = list(string)
  description = "list of env secrets to add to posted payload"
  default=["SECRET=supersecret123"]
}