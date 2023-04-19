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

variable "public_tag" {
    type = string
    default =  "osconfig_deploy_secret_ssh_public"
}

variable "private_tag" {
    type = string
    default =  "osconfig_deploy_secret_ssh_private"
}

variable "timeout" {
    type = string
    default = "600s"
}