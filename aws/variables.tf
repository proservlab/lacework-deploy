variable "region" {
  description = "default aws region"
  default     = "us-east-1"
  type        = string
}

# backend configuration
variable "terraform_backend_bucket" {
  description = "terraform backend bucket name"
  type        = string
}

variable "terraform_backend_region" {
  description = "terraform backend region"
  type        = string
}
variable "terraform_backend_profile" {
  description = "terraform backend profile"
  type        = string
}
variable "terraform_backend_key" {
  description = "terraform backend key"
  type        = string
}
variable "terraform_backend_encrypt" {
  description = "terraform backend encrypt"
  type        = bool
}
variable "terraform_backend_dynamodb_table" {
  description = "terraform backend dynamodb table"
  type        = string
}

variable "cluster_name" {
  description = "name of the eks cluster"
  default     = "proservlab-cluster"
}

variable "lacework_profile" {
  description = "lacework account profile name"
  default     = "proservlab"
}

variable "lacework_account_name" {
  description = "lacework account name"
  default     = "proservlab"
}

variable "slack_token" {
  description = "slack token to use for notifications"
  default     = false
}

variable "lacework_agent_access_token" {
  description = "lacework agent token"
  type        = string
}

variable "proxy_token" {
  type        = string
  description = "proxy token used by the admissions controller"
}