variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "cluster_name" {
  type    = string
}

variable "gcp_project_id" {
  type = string
}

variable "gcp_location" {
  type = string
}

variable "kubeconfig_path" {
  type = string
  description = "kubeconfig path"
}