variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "role" {
    type = string
    description = "role context for ec2 profile"
}