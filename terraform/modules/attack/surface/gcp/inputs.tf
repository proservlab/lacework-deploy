##################################################
# Context
################################################## 

variable "parent" {
  type = list(string)
  default = []
} 

variable "config" {
  type = any
  description = "Schema defined in modules/context/attack/surface"
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}

variable "default_gcp_project" {
  type = string
  description = "gcp project"
}
variable "default_gcp_region" {
  type = string
  description = "gcp region"
}
variable "attacker_gcp_project" {
  type = string
  description = "gcp project"
}
variable "attacker_gcp_region" {
  type = string
  description = "gcp region"
}
variable "target_gcp_project" {
  type = string
  description = "gcp project"
}
variable "target_gcp_region" {
  type = string
  description = "gcp region"
}
variable "default_kubeconfig" {
  type = string
  description = "kubeconfig path"
}
variable "attacker_kubeconfig" {
  type = string
  description = "kubeconfig path"
}
variable "target_kubeconfig" {
  type = string
  description = "kubeconfig path"
}
variable "default_lacework_profile" {
  type = string
  description = "lacework profile"
}
variable "default_lacework_account_name" {
  type = string
  description = "lacework account name"
}
variable "default_lacework_server_url" {
  type = string
  description = "lacework server url"
}
variable "default_lacework_agent_access_token" {
  type = string
  description = "lacework agent access token"
}
variable "default_lacework_proxy_token" {
  type = string
  description = "lacework proxy token"
}