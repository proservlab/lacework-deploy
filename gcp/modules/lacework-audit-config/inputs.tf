variable "environment" {
    type    = string
}

variable "gcp_organization" {
    type            = string
    description     = "gcp organization where lacework config should be stored"
}

variable "lacework_gcp_project" {
    type            = string
    description     = "gcp project id where lacework config should be stored"
}