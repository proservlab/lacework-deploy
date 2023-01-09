variable "environment" {
  type    = string
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