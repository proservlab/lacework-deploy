variable "aws_region" {
  default = "us-east-1"
}

variable "environment" {
  type    = string
}

variable "cluster-name" {
  default = "terraform-cluster"
  type    = string
}
