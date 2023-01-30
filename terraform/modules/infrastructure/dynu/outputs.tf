output "records" {
    value = var.records
}

output "cname_records" {
    value = null_resource.cname_dns_record
}

output "a_records" {
    value = null_resource.a_dns_record
}