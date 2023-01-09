variable "environment" {
  type    = string
}

variable "resource_query_exec_reverse_shell_attacker" {
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
                        Key = "ssm_exec_reverse_shell_attacker"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "listen_ip" {
  type = string
  description = "IP address of attacker"
  default = "0.0.0.0"
}

variable "listen_port" {
  type = number
  description = "Port address of attacker"
  default = 4444
}

variable "payload" {
  type = string
  description = "The bash commands payload to execute when target machine connects"
  default = <<-EOT
  touch /tmp/pwned
  EOT
}