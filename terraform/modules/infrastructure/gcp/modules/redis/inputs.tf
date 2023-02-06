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

variable "redis_enabled" {
  default = false
}

variable "redis_memory_in_gb" {
  default = 1
}

variable "redis_ha_enabled" {
  default = false
}