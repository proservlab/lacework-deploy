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