variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                region = string
                payload = string
                attack_delay = string
                user_list = string
                password_list = string
                task = string
                reverse_shell_host = string
                reverse_shell_port = string
        })
        description = "inherit variables from the parent"
}