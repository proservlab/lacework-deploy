variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                region = string
                compromised_credentials = string
                compromised_keys_user = string
                protonvpn_user = string
                protonvpn_password = string
                protonvpn_tier = string
                protonvpn_server = string
                protonvpn_protocol = string
                protonvpn_privatekey = string
                ethermine_wallet = string
                minergate_user = string
                nicehash_user = string
                attack_delay = string
        })
        description = "inherit variables from the parent"
}