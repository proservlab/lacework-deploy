variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
  type    = string
}

variable "tag" {
  type = string
  default = "ssm_exec_docker_nmap"
}

variable "timeout" {
  type = number
  default = 3600
}

variable "cron" {
  type = string
  default = "cron(0 */1 * * ? *)"
}

variable "image" {
  type = string
  description = "docker image to use"
  default =  "ghcr.io/credibleforce/proxychains-nmap:main"
}

variable "container_name" {
  type = string
  description = "docker container name"
  default =  "nmap"
}

variable "use_tor" {
  type = bool
  description = "whether to use the tor network for scanning"
  default = false
}

variable "ports" {
  type = list(number)
  description = "list of ports to scan on target"
  default = [
    22,80,443,5000,8000,8080,8091
  ]
}

variable "targets" {
  type = list(string)
  description = "target to use for brute force - default is local network"
  default = []
}