variable "dynu_api_token" {
    type = string
    description = "The API key for your Dynu account"
}

variable "dynu_dns_domain" {
    type = string
    description = "The hostname you want to update"
}

variable "records" {
    type = list(object({
        recordType = string
        recordName = string
        recordHostName = string
        recordValue = string
    }))
    validation {
        condition     = length([ for record in var.records: record if contains(["a","cname"],record.recordType) ]) == length(var.records)
        error_message = "Type must be either 'a' or 'cname'."
    }
}
