variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                minergate_image = string
                minergate_name = string
                minergate_server = string
                minergate_user = string
                attack_delay = number
        })
        description = "inherit variables from the parent"
}