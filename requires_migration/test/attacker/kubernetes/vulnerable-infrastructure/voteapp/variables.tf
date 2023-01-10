variable "account_name" {
  default = "proservlab"
}

variable "environment" {
  default = "proservlab"
}

variable "app" {
  default = "vote"
}

variable "region" {
  default = "us-east-1"
}

variable "tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "latest"
}

variable "image_name" {
  description = "Name to use for deployed Docker image"
  type        = string
  default     = "voteapp/vote"
}

variable "source_path" {
  description = "Path to Docker image source"
  type        = string
  default     = "vote"
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