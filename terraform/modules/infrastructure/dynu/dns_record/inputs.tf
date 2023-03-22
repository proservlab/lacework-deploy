variable "dynu_dns_domain" {
    type = string
    description = "The hostname you want to update"
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
