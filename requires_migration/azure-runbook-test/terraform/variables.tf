variable "region" {
  description = "default azure region"
  default     = "West US 2"
  type        = string
}

variable "environment" {
  description = "environment"
  default     = "target"
  type        = string
}