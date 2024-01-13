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

variable "ssh_public_key_path" {
    type = string
    description = "path to write ssh public key"
    default = "/home/ubuntu/.ssh/secret_key"
}

variable "ssh_private_key_path" {
    type = string
    description = "path to write ssh private key"
    default = "/home/ubuntu/.ssh/secret_key.pub"
}

variable "ssh_authorized_keys_path" {
    type = string
    description = "path to append ssh authorized key"
    default = "/home/ubuntu/.ssh/authorized_keys"
}
