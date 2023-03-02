variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "cluster_name" {
  type    = string
}

variable "lacework_agent_access_token" {
    type    = string
}

variable "lacework_server_url" {
    type    = string
    default = "https://api.lacework.net"
}

variable "lacework_image_repository" {
    type    = string
    default = "lacework/datacollector-windows"
}

variable "lacework_image_tag" {
    type    = string
    default = "6.3.0"
}

variable "lacework_cluster_agent_enable" {
    type    = bool
    default = false
}

variable "lacework_cluster_agent_image_repository" {
    type    = string
    default = "lacework/k8scollector"
}

variable "lacework_cluster_agent_cluster_type" {
    type    = string
    default = "eks"
}

variable "lacework_cluster_agent_cluster_region" {
    type    = string
    default = "us-east-1"
}

variable "syscall_config" {
    type = string
    default = ""
}
