variable "environment" {
    type = string
    description = "name of the environment"
}

variable "deployment" {
    type = string
    description = "unique deployment id"
}

variable "tag" {
  type = string
  default = "ssm_exec_vuln_npm_app_attacker"
}

variable "timeout" {
  type = number
  default = 1200
}

variable "cron" {
  type = string
  default = "cron(0/30 * * * ? *)"
}

variable "resource_query_exec_vuln_npm_app_attacker" {
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
                        Key = "ssm_exec_vuln_npm_app_attacker"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "target_ip" {
  type = string
  description = "target ip"
}

variable "target_port" {
  type = number
  description = "target port"
}

variable "payload" {
  type = string
  description = "bash payload to execute"
  default =   <<-EOT
              touch /tmp/vuln_npm_app_pwned
              EOT
}
