variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "gcp_project_id" {
  type = string
  description = "gcp project id"
}

variable "gcp_location" {
  type = string
  description = "gcp region"
}

variable "project_filter_list" {
    type = list(string)
    description = "list of target projects"
}

variable "global" {
    type = bool
    description = "enable/disable global config"
    default = true
}

variable "regional" {
    type = bool
    description = "enable/disable regional config"
    default = true
}

variable "lacework_integration_name" {
    type = string
    description = "lacework integration name"
    default = "agentless_from_terraform"
}