variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_names" {
  type = list
  description = "eks cluster names"
}
