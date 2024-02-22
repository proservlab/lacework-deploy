variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                attack_delay = string
                image = string
                container_name = string
                use_tor = string
                ports = list(number)
                targets = list(string)
        })
        description = "inherit variables from the parent"
}