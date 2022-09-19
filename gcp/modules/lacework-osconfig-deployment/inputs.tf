variable "environment" {
    type    = string
}

variable "gcp_location" {
    type = "string"
}

variable "gcp_project" {
    type    = string
}

variable "lacework_agent_access_token" {
    type    = string
}

variable "lacework_server_url" {
  description = "lacework server url"
  type = string
  default = "https://api.lacework.net"
}