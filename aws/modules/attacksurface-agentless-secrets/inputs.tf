variable "environment" {
  type    = string
}

variable "resource_query_deploy_secret_ssh_private" {
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
                        Key = "ssm_deploy_secret_ssh_private"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "resource_query_deploy_secret_ssh_public" {
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
                        Key = "ssm_deploy_secret_ssh_public"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}