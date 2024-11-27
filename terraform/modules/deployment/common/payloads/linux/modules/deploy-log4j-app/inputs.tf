variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                listen_port = string
                trusted_addresses = list(string)
        })
        description = "inherit variables from the parent"
}