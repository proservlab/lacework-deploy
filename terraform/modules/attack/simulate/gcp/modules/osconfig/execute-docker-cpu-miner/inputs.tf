variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
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

variable "resource_query_exec_docker_cpuminer" {
    type    = object({
      ResourceTypeFilters = list(string)
      TagFilters  = list(object({
        Key = string
        Values = list(string)
      }))
    })
    description = "JSON query to idenfity resources which will have lacework deployed"
    default = {
                ResourceTypeFilters = [
                    "AWS::EC2::Instance"
                ]

                TagFilters = [
                    {
                        Key = "ssm_exec_docker_cpuminer"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}