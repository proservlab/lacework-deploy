variable "environment" {
  type    = string
}

variable "resource_query_exec_docker_log4shell_attacker" {
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
                        Key = "ssm_exec_docker_log4shell_attacker"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "attacker_http_port" {
  type = number
  description = "listening port for webserver in container"
  default=8088
}

variable "attacker_ldap_port" {
  type = number
  description = "listening port for ldap in container"
  default=1389
}

variable "attacker_ip" {
  type = number
  description = "attacker ip"
}