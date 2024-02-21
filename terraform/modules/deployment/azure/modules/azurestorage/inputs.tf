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

variable "storage_resource_group_name" {
  type = string
}

variable "storage_virtual_network_name" {
  type = string
}

variable "storage_virtual_network_id" {
  type = string
}

variable "storage_subnet_network" {
  type = list(string)
  default = ["10.0.2.0/24"]
}

variable "public_network_access_enabled" {
  type = bool
  default = false
}

variable "trusted_networks" {
  type = list(string)
  default = ["10.0.2.0/24"]
}

variable "account_tier" {
  default = "Standard"
}

variable "account_replication_type" {
  default = "GRS"
}

