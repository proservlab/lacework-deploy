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
  description = "gcp region"
}

variable "use_pub_sub" {
  type = bool
  description = "enable use of v2 pub sub integration"
  default = false
}

variable "org_integration" {
  type = bool
  description = "enable or disable org level logging"
  default = false
}

variable "enable_gcp_data_access_logging" {
  type = bool
  description = "enable gcp data access logging"
  default = false
}