##################################################
# Context
##################################################

variable "config" {
  type = any
  description = "Schema defined in modules/context/attack/simulate"
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}

variable "compromised_credentials" {
  type = any
}

variable "public_resource_group" {
  type = any
}

variable "private_resource_group" {
  type = any
}

variable "target_public_resource_group" {
  type = any
}

variable "target_private_resource_group" {
  type = any
}

variable "attacker_public_resource_group" {
  type = any
}

variable "attacker_private_resource_group" {
  type = any
}

variable "parent" {
  type = list(string)
  default = []
} 