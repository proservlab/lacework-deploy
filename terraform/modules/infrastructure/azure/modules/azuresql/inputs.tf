variable "environment" {
  type = string
  description = "name of the environment"
}

variable "deployment" {
  type = string
  description = "unique deployment id"
}

variable "region" {
  type = string
}

variable "server_name" {
  type = string
  default = "azuresql"
}

variable "db_name" {
  type = string
  default = "dev"
}

variable "db_resource_group_name" {
  type = string
}

variable "db_virtual_network_name" {
  type = string
}

variable "db_virtual_network_id" {
  type = string
}

variable "db_subnet_network" {
  type = list(string)
  default = ["10.0.2.0/24"]
}

variable "public_network_access_enabled" {
  type = bool
  default = false
}

variable "sql_engine" {
  type = string
  default = "postgres"

  validation {
    condition     = contains(["mysql", "postgres"], var.sql_engine)
    error_message = "Must be either \"mysql\" or \"postgres\"."
  }
}

variable "instance_type" {
  default = "postgres"
}

variable "sku_name" {
  default = "GP_Gen5_2"
}

variable "root_db_username" {
  default = "dbuser"
}

variable "root_db_password" {
  default = null
}

