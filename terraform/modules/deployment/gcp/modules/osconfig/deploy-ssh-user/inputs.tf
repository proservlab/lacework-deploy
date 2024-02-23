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

variable "tag" {
    type = string
    default =  "osconfig_deploy_ssh_user"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "username" {
  type = any
  description = "user name to add to local system"
  default = "lou.caloozer"
}

variable "password" {
  type = string
  description = "password for new local user - default is random"
  default = null
}
