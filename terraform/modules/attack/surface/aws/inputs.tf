##################################################
# Context
################################################## 

variable "config" {
  type = any
  description = "Schema defined in modules/context/attack/surface"
}

variable "infrastructure" {
  type = object({
    config = any
    deployed_state = any
  })
}