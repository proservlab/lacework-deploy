variable "environment" {
  type    = string
}

variable "resource_query_deploy_inspector_agent" {
    type    = object({
      ResourceTypeFilters = list(string)
      TagFilters  = list(object({
        Key = string
        Values = list(string)
      }))
    })
    description = "JSON query to idenfity resources which will have inspector agent deployed"
    default = {
                ResourceTypeFilters = [
                    "AWS::EC2::Instance"
                ]

                TagFilters = [
                    {
                        Key = "ssm_deploy_inspector_agent"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}