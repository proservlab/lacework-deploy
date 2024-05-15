variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "tag" {
  type = string
  default = "ssm_connect_enumerate_host"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
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