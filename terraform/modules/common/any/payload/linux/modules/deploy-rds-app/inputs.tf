variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                listen_port = string
                db_host = string
                db_name = string
                db_user = string
                db_password = string
                db_port = string
                db_region = string
        })
        description = "inherit variables from the parent"
}