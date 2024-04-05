variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                retry_delay = number
        })
        description = "inherit variables from the parent"
}