variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "region" {
    type = string
    description = "azure region"
}

variable "resource_group" {
  description = "resource group"
  type = any
}

variable "automation_account" {
    type = string
    description = "automation account name"
}

variable "automation_princial_id"{
    type = string
    description = "automation account principal id"
}

variable "tag" {
    type = string
    description = "tag associated with this runbook"
    default = "runbook_exec_docker_nmap"
}

variable "attack_delay" {
  type = number
  description = "wait time between baseline and attack (default: 12 hours)"
  default =  50400
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
    22,80,443,1433,3306,5000,5432,5900,6379,8000,8080,8088,8090,8091,9200,27017
  ]
}

variable "targets" {
  type = list(string)
  description = "target to use for brute force - default is local network"
  default = []
}