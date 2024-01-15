variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "gcp_location" {
    type = string
}

variable "gcp_project_id" {
    type    = string
}

variable "tag" {
    type = string
    default = "osconfig_exec_docker_exploit_log4j"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "compromised_credentials" {
  type = any
  description = "credentials to use in compromised keys attack"
}

variable "compromised_keys_user" {
  type = string
  default = "khon.traktour@interlacelabs"
}

variable "commands" {
  type = list(string)
  description = "list of gcp cli commands to run"
  default = ["gcloud auth list"]
}