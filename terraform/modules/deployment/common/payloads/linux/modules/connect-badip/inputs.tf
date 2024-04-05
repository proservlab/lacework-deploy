variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                iplist_url = string
                retry_delay_secs = number
        })
        description = "inherit variables from the parent"
}