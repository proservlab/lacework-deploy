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
  default = "ssm_connect_bad_ip"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}

variable "iplist_url" {
  type = string
  description = "url to obtain a list of bad ips"
  default = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
}