variable "inputs" {
        type = object({
                environment = string
                deployment = string
                tag = string
                timeout = optional(string)
                cron = optional(string)
                nmap_scan_host = string
                nmap_scan_ports = list(number)
        })
        description = "inherit variables from the parent"
}