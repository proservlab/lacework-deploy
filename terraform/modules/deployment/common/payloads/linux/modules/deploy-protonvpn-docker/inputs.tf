variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                protonvpn_user = string
                protonvpn_password = string
                protonvpn_tier = string
                protonvpn_server = string
                protonvpn_protocol = string
        })
        description = "inherit variables from the parent"
}