variable "environment" {
  type    = string
}

variable "lacework_agent_access_token" {
    type    = string
}

variable "lacework_server_url" {
    type    = string
    default = "https://api.lacework.net"
}

variable "resource_query" {
    type    = string
    description = "JSON query to idenfity resources which will have lacework deployed"
    default = <<EOT
      {
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
    EOT
}