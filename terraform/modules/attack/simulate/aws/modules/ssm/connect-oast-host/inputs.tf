variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "resource_query_connect_oast_host" {
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
                        Key = "ssm_connect_oast_host"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}