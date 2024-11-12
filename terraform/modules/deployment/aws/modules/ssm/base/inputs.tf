variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "tag" {
  type = string
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}

variable base64_payload {
    type = string
    default = "H4sIAOGxM2cAA1NWKMnILFYAokSFgpzE5NSM/JyU1CIAWxoc1RcAAAA="
}

variable base64_powershell_payload {
    type = string
    default = "H4sIAOGxM2cAA1NWKMnILFYAokSFgpzE5NSM/JyU1CIAWxoc1RcAAAA="
}