variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                docker_users = list(string)
        })
        description = "inherit variables from the parent"
}