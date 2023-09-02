variable "default_aws_profile" {
    type = string
    default = null
}

variable "default_aws_region" {
    type = string
    default = "us-east-1"
}

variable "create_and_assume_role" {
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
