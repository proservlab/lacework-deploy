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
    default = "osconfig_deploy_lacework"
}

variable "timeout" {
    type = string
    default = "600s"
}

variable "lacework_agent_tags" {
  type        = map(string)
  description = "A map/dictionary of Tags to be assigned to the Lacework datacollector"
  default     = {}
}

variable "lacework_agent_temp_path" {
  type        = string
  description = "The temporary path for the Lacework installation script"
  default     = "/tmp"
}

variable "lacework_agent_access_token" {
    type    = string
}

variable "lacework_server_url" {
  description = "lacework server url"
  type = string
  default = "https://agent.lacework.net"
}