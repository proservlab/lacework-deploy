variable "account_name" {
  default = "root"
}

variable "environment" {
  default = "proservlab"
}

variable "region" {
  default = "us-east-1"
}

variable "source_path" {
  default = "certs"
}

variable "hash_script" {
  description = "Path to script to generate hash of source contents"
  type        = string
  default     = ""
}

variable "cluster_name" {
  default = "proservlab-cluster"
}

variable "proxy_token" {
  description = "Proxy scanner token"
}