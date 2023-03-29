##################################################
# Context
##################################################

variable "parent" {
  type = list(string)
  default = []
} 

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

variable "cluster_name" {
  type = string
  default = null
}