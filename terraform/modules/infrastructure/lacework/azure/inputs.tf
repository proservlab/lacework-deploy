##################################################
# Context
##################################################

variable "parent" {
  type = list(string)
  default = []
} 

variable "config" {
  type = any
  description = "Schema defined in modules/context/infrastructure"
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}

variable "default_azure_subscription" {
  type = string
  description = "azure subscription"
}
variable "default_azure_tenant" {
  type = string
  description = "azure tenant"
}
variable "default_azure_region"{
  type = string
  description = "azure profile"
}
variable "attacker_azure_subscription" {
  type = string
  description = "azure subscription"
}
variable "attacker_azure_tenant" {
  type = string
  description = "azure tenant"
}
variable "attacker_azure_region"{
  type = string
  description = "azure profile"
}
variable "target_azure_subscription" {
  type = string
  description = "azure subscription"
}
variable "target_azure_tenant" {
  type = string
  description = "azure tenant"
}
variable "target_azure_region"{
  type = string
  description = "azure profile"
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
variable "default_lacework_sysconfig_path" {
  type = string
  description = "lacework syscall config path"
}