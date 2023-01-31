##################################################
# Context
##################################################

variable "config" {
  type = any
  description = "For validation and structure see ./modules/context/infrastructure/inputs.tf"
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}