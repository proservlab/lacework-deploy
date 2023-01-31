variable "dynu_api_token" {
    type = string
}

variable "dynu_dns_domain" {
    type = string
}

variable records {
    type = list(object({
        recordType = string
        recordName = string
        recordValue = string
    }))
    validation {
        condition     = length([ for record in var.records: record if contains(["a","cname"],record.recordType) ]) == length(var.records)
        error_message = "Type must be either 'a' or 'cname'."
    }
}