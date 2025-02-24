variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "cluster_name" {
  type = string
  description = "name of the kubernetes cluster"
}

variable "lacework_agent_access_token" {
    type    = string
}

variable "lacework_server_url" {
    type    = string
    default = "https://agent.lacework.net"
}

variable "lacework_image_repository" {
    type    = string
    default = "lacework/datacollector"
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
