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

variable "private_resource_group" {
    type = any
    description = "private azure resource group for runbook from compute"
}

variable "tag" {
    type = string
    description = "tag associated with this runbook"
    default = "runbook_exec_touch_file"
}