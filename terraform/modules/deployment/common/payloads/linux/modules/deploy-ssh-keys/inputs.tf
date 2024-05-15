variable "inputs" {
        type = object({
                environment = string
                deployment = string
                public_tag = string
                private_tag = string
                timeout = optional(string)
                cron = optional(string)
                ssh_public_key_path = string
                ssh_private_key_path = string
                ssh_authorized_keys_path = string
        })
        description = "inherit variables from the parent"
}