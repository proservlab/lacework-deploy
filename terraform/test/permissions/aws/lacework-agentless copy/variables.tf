variable "default_aws_profile" {
    type = string
    default = null
}
variable "create_role" {
    type = bool
    default = false
}

variable "assume_role_apply" {
    type = bool
    default = false
}

variable "role_policy_path" {
    type = string
    default = "../lacework-agentless-policy.json"
}

variable "role_name" {
    type = string
    default = "lacework-agentless"
}
