variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                iplist_url = string
        })
        description = "inherit variables from the parent"
}