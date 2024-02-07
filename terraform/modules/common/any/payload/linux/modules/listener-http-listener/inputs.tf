variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                listen_ip = string
                listen_port = string
        })
        description = "inherit variables from the parent"
}