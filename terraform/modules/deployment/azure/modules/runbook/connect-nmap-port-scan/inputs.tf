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
    default = "runbook_connect_enumerate_host"
}

variable "nmap_scan_host" {
  type = string
  description = "the host to port scan"
  default = "portquiz.net"
}

variable "nmap_scan_ports" {
  type = list(number)
  description = "the ports to scan on target host"
  default = [80,443,23,22,8080,3389,27017,3306,6379,5432,389,636,1389,1636]
}