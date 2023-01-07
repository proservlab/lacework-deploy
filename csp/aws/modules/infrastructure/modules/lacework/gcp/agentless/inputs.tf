variable "environment" {
    type    = string
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
    type = bool
    description = "lacework integration name"
    default = "agentless_from_terraform"
}