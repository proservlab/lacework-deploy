variable "dynu_dns_domain" {
    type = string
    description = "The hostname the domain to be updated"
}

variable "dynu_api_key" {
    type = string
    description = "The dynu api key"
}

variable "record" {
    type = object({
        recordType = string
        recordName = string
        recordHostName = string
        recordValue = string
    })
    validation {
        condition     = contains(["A","CNAME"],var.record.recordType)
        error_message = "recordType must be either 'A' or 'CNAME'."
    }
}
