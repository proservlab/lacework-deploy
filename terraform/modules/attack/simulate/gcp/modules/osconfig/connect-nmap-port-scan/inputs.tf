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
    default = "osconfig_connect_enumerate_host"
}

variable "timeout" {
    type = string
    default = "600s"
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