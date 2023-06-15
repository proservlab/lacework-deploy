variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "gcp_project_id" {
  type = string
  description = "gcp project id"
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