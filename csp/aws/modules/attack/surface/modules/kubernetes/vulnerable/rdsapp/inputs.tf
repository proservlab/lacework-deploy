variable "environment" {
    type = string
}

variable "region" {
    type = string
}

variable "app" {
  default = "rdsapp"
}

variable "tag" {
  description = "Tag to use for deployed Docker image"
  type        = string
  default     = "latest"
}

variable "image_name" {
  description = "Name to use for deployed Docker image"
  type        = string
  default     = "rdsapp/app"
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

variable "namespace" {
    type = string
    default = "rdsapp"
}

variable "root_db_username" {
    type = string
    description = "root admin username"
    default = "dbuser"
}

variable "root_db_password" {
    type = string
    description = "root admin password"
    default = "dbpassword"
}

variable "service_account_db_user" {
    type = string 
    description = "kubernetes service account db username for rds iam auth"
    default = "workshop_user"
}

variable "service_account" {
    type = string 
    description = "kubernetes service account name for rds iam auth"
    default = "database"
}

variable "database_name" {
    type = string
    description = "name of application database"
    default = "dev"
}

variable "database_port" {
    type = number
    description = "port for rds database service"
    default = 3306
}

variable "cluster_vpc_id" {
    type = string
    description = "VPC id for the cluster - used to lb security group"
}

variable "cluster_vpc_subnet" {
    type = string 
    description = "VPC subnet"
}

variable "cluster_sg_id" {
    type = string 
    description = "Security group for the cluster nodes"
}

variable "cluster_openid_connect_provider_arn" {
    type = string
    description = "OIDC  provider arn for cluster"
}

variable "cluster_openid_connect_provider_url" {
    type = string
    description = "OIDC provider url for cluster"
}

variable "service_port" {
  type = number
  description = "External port to expose result service on"
  default = 8080
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