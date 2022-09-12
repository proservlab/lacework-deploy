variable "environment_name" {
  type = string
}

variable "cluster_version" {
  default = "1.22"
}

variable "project_id" {
  type = string
}

variable "region" {
  default = "us-central1"
}

variable "nodes_instance_type" {
  default = "e2-medium"
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
