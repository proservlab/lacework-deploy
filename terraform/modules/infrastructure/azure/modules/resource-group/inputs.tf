variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
  description = "default azure region"
  default     = "West US 2"
  type        = string
}

variable "name" {
    type = string
    description = "name of the resource group - environment and deployment will be appended"
}