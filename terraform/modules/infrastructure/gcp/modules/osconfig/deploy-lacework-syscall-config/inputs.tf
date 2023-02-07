variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "gcp_location" {
    type = string
}

variable "gcp_project_id" {
    type    = string
}

variable "label" {
    type = map(string)
    default =   {
                    osconfig_deploy_lacework = "true"
                }
}

variable "syscall_config" {
  type = string
  description = "Configuration file path syscall_config.yaml"
  default = "./resources/syscall_config.yaml"
}