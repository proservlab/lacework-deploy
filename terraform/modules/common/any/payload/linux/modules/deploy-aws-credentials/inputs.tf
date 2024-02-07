variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                compromised_credentials = string
                compromised_keys_user = string
        })
        description = "inherit variables from the parent"
}