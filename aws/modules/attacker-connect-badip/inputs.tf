variable "environment" {
  type    = string
}

variable "resource_query_connect_bad_ip" {
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
                        Key = "ssm_connect_bad_ip"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}