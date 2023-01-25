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
}

variable "gcp_location" {
  type = string
}


# variable "vpc_security_group_ids" {
#     type    = list(string)
#     default = []
# }

variable "subnet_id" {
    type    = string
}

# variable "iam_instance_profile" {
#     type    = string
#     default = null
# }

variable "instance_type" {
    type    = string
    default = "e2-micro"
}

variable "ami" {
    type    = "debian-cloud/debian-11"
}

variable "tags" {
    type    = map(any)
    default = {}
}

variable user_data {
    type    = string
    default =   <<-EOT
                #! /bin/bash
                sudo apt update
                sudo apt -y install google-osconfig-agent
                EOT
}

variable user_data_base64 {
    type    = string
    default = null
}

variable "service_account_email" {
    type = string
}