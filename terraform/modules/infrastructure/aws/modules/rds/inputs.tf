variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable region {
  type  = string
}

variable "igw_id" {
    type = string
    description = "IGW id for subnet"
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

variable "ec2_instance_role_name" {
    type = string
    description = "The ec2 instance role name to create and grant db policies access"
}

variable "user_role_name" {
    type = string
    description = "The user instance role name to grant db policies access"
}

variable "instance_type" {
    type = string
    description = "The instance type for the database"
}

variable "root_db_username" {
    type = string
    description = "root admin username"
    default = "dbuser"
}

variable "database_name" {
    type = string
    description = "name of the database to store in parameter store"
    default = "dev"
}

variable "database_port" {
    type = number
    description = "port for rds database service"
    default = 3306
}