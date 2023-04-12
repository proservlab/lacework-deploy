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
    default = "https://api.lacework.net"
}