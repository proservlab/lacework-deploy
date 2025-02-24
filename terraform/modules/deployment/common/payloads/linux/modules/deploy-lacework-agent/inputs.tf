variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                lacework_agent_tags = map(string)
                lacework_agent_temp_path = string
                lacework_agent_access_token = string
                lacework_server_url = string
        })
        description = "inherit variables from the parent"
}