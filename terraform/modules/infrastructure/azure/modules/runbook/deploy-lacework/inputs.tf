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
    default = "runbook_deploy_lacework"
}

variable "lacework_agent_tags" {
  type        = map(string)
  description = "A map/dictionary of Tags to be assigned to the Lacework datacollector"
  default     = {}
}

variable "lacework_agent_temp_path" {
  type        = string
  description = "The temporary path for the Lacework installation script"
  default     = "/tmp"
}

variable "lacework_agent_access_token" {
    type    = string
}

variable "lacework_server_url" {
    type    = string
    default = "https://agent.lacework.net"
}