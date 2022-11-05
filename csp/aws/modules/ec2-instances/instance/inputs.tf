variable "environment" {
  type    = string
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

variable user_data {
    type    = string
    default = null
}

variable user_data_base64 {
    type    = string
    default = null
}