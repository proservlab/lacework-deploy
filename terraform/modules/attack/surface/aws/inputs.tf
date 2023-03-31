##################################################
# Context
################################################## 

variable "parent" {
  type = list(string)
  default = []
} 

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

variable "compromised_credentials" {
  type = any
  default = ""
}

variable "cluster_name" {
  type = string
  default = null
}