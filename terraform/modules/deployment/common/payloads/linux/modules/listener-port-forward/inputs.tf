variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                host_ip = string
                port_forwards = list(object({
                                        src_port      = number
                                        dst_port      = number
                                        dst_ip        = string
                                        description   = string
                                }))
                host_port = string
        })
        description = "inherit variables from the parent"
}