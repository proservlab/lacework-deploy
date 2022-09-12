variable "environment_name" {
  type = string
}

variable "cluster_version" {
  default = "1.22"
}

variable "cluster_username" {
  default = ""
}

variable "cluster_password" {
  default = ""
}

variable "project_id" {
  type = string
}

variable "region" {
  default = "us-central1"
}

variable "nodes_instance_type" {
  default = "n1-standard-1"
}

variable "nodes_desired_capacity" {
  default = 1
}

variable "nodes_min_size" {
  default = 1
}

variable "nodes_max_size" {
  default = 1
}
