variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
    type    = string
}

variable "user_policies" {
    type = map(any)
    description = "list of iam policies to create"
    default = []
}

variable "user_roles" {
    type = map(any)
    description = "list of iam roles to create"
    default = []
}

variable "users" {
    type = list(any)
    description = "list of users to create"
    default = []
}