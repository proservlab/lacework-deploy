variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "resource_query_exec_vuln_npm_app_target" {
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
                        Key = "ssm_exec_vuln_npm_app_target"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "listen_port" {
  type = number
  description = "listening port for container"
  default=8000
}