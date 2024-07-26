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
    description = "region to deploy entra id resources"
    default = "West US 2"
}

# allow users to choose to enable/disable entra integration
variable "enable_entra_id_activity_logs" {
    type = bool
    description = "enable or disable entra id integration"
    default = false
}