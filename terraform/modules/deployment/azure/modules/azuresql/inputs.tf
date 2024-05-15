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
    description = "azure region"
}

variable "server_name" {
  type = string
  default = "azuresql"
}

variable "add_service_principal_access" {
  type = bool
  default = false
}

variable "service_principal_display_name" {
  type = string
  default = null
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
  default = "GP_Standard_D2ds_v4"
}

variable "root_db_username" {
  default = "dbuser"
}

variable "root_db_password" {
  default = null
}

variable "mysql_authorized_ip_ranges" {
  type = list(object({
    start_ip_address = string
    end_ip_address = string
  }))
  default = []
}

variable "postgres_authorized_ip_ranges" {
  type = list(object({
    start_ip_address = string
    end_ip_address = string
  }))
  default = []
}

