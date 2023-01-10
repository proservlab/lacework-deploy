variable "environment" {
  type = string
}

variable "lacework_proxy_token" {
  type = string
  description = "lacework proxy scanner token"
  default = null
}

variable "lacework_account_name" {
  type = string
  description = "lacework account name"
}

variable "use_self_signed_certs" {
  type = bool
  default = true
}


variable "namespace" {
  type        = string
  description = "The Kubernetes namespace in which to deploy the admission controller and (optionally) the proxy scanner."
  default     = "lacework"
}
variable "admission_controller_name" {
  type        = string
  description = "The name for the Lacework admission controller deployment."
  default     = "lacework-admission-controller"
}