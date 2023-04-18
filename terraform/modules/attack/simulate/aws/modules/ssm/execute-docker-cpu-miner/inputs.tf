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
  default = "ssm_exec_docker_cpuminer"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}

# variable "nicehash_image" {
#     type = string
#     description = "nicehash docker image"
# }

# variable "nicehash_name" {
#     type = string
#     description = "nicehash docker name"
# }

# variable "nicehash_server" {
#     type = string
#     description = "nicehash server"
# }

# variable "nicehash_user" {
#     type = string
#     description = "nicehash user"
# }

variable "minergate_image" {
    type = string
    description = "minergate docker image"
}
variable "minergate_name" {
    type = string
    description = "minergate docker name"
}

variable "minergate_server" {
    type = string
    description = "minergate server"
}

variable "minergate_user" {
    type = string
    description = "minergate user"
}