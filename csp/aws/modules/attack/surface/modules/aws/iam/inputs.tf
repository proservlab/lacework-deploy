variable "environment" {
    type    = string
}

variable "region" {
    type    = string
}

variable "user_policies" {
    type = map(string)
    description = "list of role to create"
}

variable "users" {
    type = list(object({
        name = string
        policy = string
    }))
}