variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "app" {
  default = "vote"
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

variable "app_namespace" {
  type = string
  description = "Namespace for the application"
  default = "vote"
}

variable "maintenance_namespace" {
  type = string
  description = "Namespace for the attack surface maintenance pod"
  default = "maintenance"
}

variable "cluster_vpc_id" {
  type = string
  description = "VPC id for the cluster - used to lb security group"
}

variable "secret_credentials" {
  type = string
  description = "Credentials to store in secret"
  default = <<-EOT
    AWS_ACCESS_KEY_ID=FAKE-KEY
    AWS_SECRET_ACCESS_KEY=FAKE-SECRET
    AWS_DEFAULT_REGION=us-east-1
    AWS_DEFAULT_OUTPUT=json
  EOT
}

variable "vote_service_port" {
  type = number
  description = "External port to expose vote service on"
  default = 8001
}

variable "result_service_port" {
  type = number
  description = "External port to expose result service on"
  default = 8002
}

variable "trusted_attacker_source" {
  type = list(string)
  description = "Allow all attacker source public addresses inbound to the app load balancer(s)"
  default = []
}

variable "trusted_workstation_source" {
  type = list(string)
  description = "Allow current workstation public address inbound to the app load balancer(s)"
  default = []
}

variable "additional_trusted_sources" {
  type = list(string)
  description = "List of additional trusted sources allowed inbound to the app load balancer(s)"
  default = []
}