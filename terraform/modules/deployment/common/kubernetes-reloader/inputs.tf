variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "app" {
  default = "reloader"
}

variable "app_namespace" {
  default = "reloader"
}

variable "ignore_namespaces" {
    type = list(string)
    default = []
}