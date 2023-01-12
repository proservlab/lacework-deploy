variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable region {
  type  = string
}

variable "cluster_name" {
  type    = string
}

variable "cluster_oidc_issuer" {
  type  = string
}