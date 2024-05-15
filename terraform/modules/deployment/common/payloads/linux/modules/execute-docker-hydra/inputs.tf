variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                region = string
                attack_delay = string
                payload = string
                image = string
                use_tor = string
                custom_user_list = list(string)
                custom_password_list = list(string)
                container_name = string
                user_list = string
                password_list = string
                targets = list(string)
                ssh_user = string
        })
        description = "inherit variables from the parent"
}