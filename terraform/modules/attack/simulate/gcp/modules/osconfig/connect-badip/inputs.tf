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

variable "label" {
    type = map(string)
    default =   {
                    osconfig_connect_bad_ip = "true"
                }
}

variable "iplist_url" {
  type = string
  description = "url to obtain a list of bad ips"
  default = "https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level2.netset"
}