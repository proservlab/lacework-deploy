variable "account_name" {
  default = "root"
}

variable "environment" {
  default = "prod"
}

variable "app" {
  default = "web-image"
}

# variable "key_name" {
#   description = "SSH key name to use"
#   default     = "devops-2018-12-19"
# }

variable "region" {
  default = "us-east-1"
}

variable "instance_type" {
  description = "AWS Instance type, if you change, make sure it is compatible with AMI, not all AMIs allow all instance types "
  default     = "t2.small"
}

variable "tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "latest"
}

variable "image_name" {
  description = "Name to use for deployed Docker image"
  type        = string
  default     = "web-image"
}

variable "source_path" {
  description = "Path to Docker image source"
  type        = string
  default     = "app"
}

variable "hash_script" {
  description = "Path to script to generate hash of source contents"
  type        = string
  default     = ""
}

variable "push_script" {
  description = "Path to script to build and push Docker image"
  type        = string
  default     = ""
}