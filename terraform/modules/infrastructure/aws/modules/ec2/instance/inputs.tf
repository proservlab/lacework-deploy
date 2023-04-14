variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "vpc_security_group_ids" {
    type    = list(string)
    default = []
}

variable "subnet_id" {
    type    = string
}

variable "iam_instance_profile" {
    type    = string
    default = null
}

variable "instance_type" {
    type    = string
    default = "t2.micro"
}

variable "ami" {
    type    = string
}

variable "tags" {
    type    = map(any)
    default = {}
}

variable "user_data" {
    type    = string
    default = null
}

variable "user_data_base64" {
    type    = string
    default = null
}

variable "enable_secondary_volume" {
    type = bool
    default = false
}