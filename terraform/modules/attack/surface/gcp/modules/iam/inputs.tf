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

variable "user_policies" {
    type = map(any)
    description = "list of iam policies to create"
}

variable "users" {
    type = list(object({
        name = string
        policy = string
    }))
}