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

variable "network" {
    type = string 
    description = "VPC network"
}

variable "subnetwork" {
    type = string 
    description = "VPC subnet"
}

variable "sql_engine" {
  default = "POSTGRES_11"
}

variable "instance_type" {
  default = "db-f1-micro"
}

variable "root_db_username" {
  default = "dbuser"
}

variable "root_db_password" {
  default = null
}

variable "user_role_name" {
  default = null
}

variable "public_service_account_email" {
    type = string
}

variable "public_app_service_account_email" {
    type = string
}

variable "private_service_account_email" {
    type = string
}

variable "private_app_service_account_email" {
    type = string
}

variable "enable_public_ip" {
    type = bool
}

variable "require_ssl" {
    type = bool
}

variable "authorized_networks" {
    type = list(string)
    default = []
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