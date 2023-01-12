variable "account_name" {
  default = "proservlab"
}

variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
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
  default     = "ecs-task/web-image"
}

variable "source_path" {
  description = "Path to Docker image source"
  type        = string
  # default     = "scratch-app"
  default     = "app"
}

variable "lacework_source_path" {
  description = "Path to Docker image source"
  type        = string
  default     = "lacework-scratch-sidecar"
}

variable "lacework_tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "latest-scratch-sidecar"
}

variable "lacework_image_name" {
  description = "Name to use for deployed Docker image"
  type        = string
  default     = "lacework/datacollector"
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