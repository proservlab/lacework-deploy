variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "resource_query_deploy_lacework_syscall" {
    type    = object({
      ResourceTypeFilters = list(string)
      TagFilters  = list(object({
        Key = string
        Values = list(string)
      }))
    })
    description = "JSON query to idenfity resources which will have lacework syscall_config.yaml deployed"
    default = {
                ResourceTypeFilters = [
                    "AWS::EC2::Instance"
                ]

                TagFilters = [
                    {
                        Key = "ssm_deploy_lacework"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "syscall_config" {
  type = string
  description = "Configuration file path syscall_config.yaml"
  default = "./resources/syscall_config.yaml"
}