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

variable "sql_enabled" {
  default = false
}

variable "sql_engine" {
  default = "POSTGRES_11"
}

variable "sql_instance_class" {
  default = "db-f1-micro"
}

variable "sql_master_username" {
  default = ""
}

variable "sql_master_password" {
  default = ""
}