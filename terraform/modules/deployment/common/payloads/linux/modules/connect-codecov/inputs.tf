variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                host_ip = string
                host_port = string
                use_ssl = string
                git_origin = string
                env_secrets = list(string)
        })
        description = "inherit variables from the parent"
}