###########################
# REGION
###########################

variable "region" {
  description = "default aws region"
  default     = "us-east-1"
  type        = string
}

##########################
# AWS
##########################

variable "attacker_aws_profile" {
  type        = string
  description = "attacker aws profile"
  default     = "target"
}

variable "target_aws_profile" {
  type        = string
  description = "target aws profile"
  default     = "target"
}