variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                host_ip = string
                host_port = string
        })
        description = "inherit variables from the parent"
}