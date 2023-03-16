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
}

variable "gcp_location" {
  type = string
}

variable "LW_CLOUDRUN_ENV_GEN" {
    type = string
    default = "gen1"
}

variable "app" {
  default = "app"
}

variable "tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "0.0.1"
}

variable "image_name" {
  description = "Name to use for deployed Docker image"
  type        = string
  default     = "helloworld/app"
}

variable "lacework_profile" {
    type = string
}