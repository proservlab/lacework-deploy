variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                username = string
                password = string
        })
        description = "inherit variables from the parent"
}