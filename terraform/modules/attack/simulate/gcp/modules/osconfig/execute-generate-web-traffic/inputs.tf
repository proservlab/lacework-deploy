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

variable "delay" {
  type = number
  description = "wait time between calling urls"
  default =  60
}

variable "urls" {
  type = list(string)
  description = "list of urls to connect to via curl"
  default =  []
}