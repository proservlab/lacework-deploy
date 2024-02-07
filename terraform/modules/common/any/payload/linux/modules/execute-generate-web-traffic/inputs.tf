variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                region = string
                delay = string
                urls = list(string)
        })
        description = "inherit variables from the parent"
}