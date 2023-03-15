##################################################
# Context
##################################################

variable "config" {
  type = any
  description = "Schema defined in modules/context/infrastructure"
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}

variable "parent" {
  type = string
  default = null
}