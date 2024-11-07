variable "create" {
  type        = bool
  default     = true
  description = "Set to `false` to prevent the module from creating any resources"
}

variable "application_name" {
  type        = string
  default     = "lacework_security_audit"
  description = "The name of the Azure Active Directory Application"
}

variable "application_owners" {
  type = list(string)
  default = []
  description = "The owners of the Azure Active Directory Application. If empty, current user will be owner"
}

variable "enable_directory_reader" {
  type = bool
  default = true
  description = "Enable Directory Reader role for this principal. This will allow Lacework to read Users/Groups/Principals from MS Graph API"
}
