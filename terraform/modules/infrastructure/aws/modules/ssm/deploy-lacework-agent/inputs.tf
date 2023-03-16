variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "lacework_agent_access_token" {
    type    = string
}

variable "lacework_server_url" {
    type    = string
    default = "https://api.lacework.net"
}

variable "resource_query" {
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
                        Key = "ssm_deploy_lacework"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}