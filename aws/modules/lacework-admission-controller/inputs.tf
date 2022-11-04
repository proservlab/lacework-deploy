variable "environment" {
  type = string
}

variable "proxy_token" {
  description = "proxy scanner token"
}

variable "lacework_account_name" {
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