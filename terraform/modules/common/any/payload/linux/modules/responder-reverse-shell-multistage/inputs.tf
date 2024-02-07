variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                region = string
                listen_ip = string
                listen_port = string
                payload = string
                attack_delay = string
                iam2rds_role_name = string
                iam2rds_session_name = string
        })
        description = "inherit variables from the parent"
}