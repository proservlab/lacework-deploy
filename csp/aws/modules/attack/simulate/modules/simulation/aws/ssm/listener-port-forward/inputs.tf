variable "environment" {
  type    = string
}

variable "resource_query_exec_port_forward_target" {
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
                        Key = "ssm_exec_port_forward_target"
                        Values = [
                            "true"
                        ]
                    }
                ]
              }
}

variable "port_forwards" {
  type = list(object({
      src_port      = number
      dst_port      = number
      dst_ip        = string
      description   = string
    }))
  description = "list of port forwards"
}

variable "host_ip" {
  type = string
  description = "ip of the tunnel server"
}

variable "host_port" {
  type = number
  description = "port of the tunnel server"
  default = 8888
}
