variable "environment" {
    type = string
}

variable "vpc_id" {
    type = string
    description = "VPC id to deploy instance to"
}

variable "vpc_subnet" {
    type = string 
    description = "VPC subnet"
}

variable "trusted_sg_id" {
    type = string 
    description = "Security group for the ec2 instance - will be trusted"
}

variable "root_db_username" {
    type = string
    description = "root admin username"
    default = "dbuser"
}

variable "root_db_password" {
    type = string
    description = "root admin password"
    default = "dbpassword"
}