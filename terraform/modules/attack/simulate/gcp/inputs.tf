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