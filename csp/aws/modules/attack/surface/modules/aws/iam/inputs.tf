variable "environment" {
    type    = string
}

variable "region" {
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