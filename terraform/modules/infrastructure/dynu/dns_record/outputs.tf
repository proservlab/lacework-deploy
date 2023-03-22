# output "records" {
#     value = restapi_object.record
# }

# output "cname_records" {
#     value = [ for r in restapi_object.record: r if jsondecode(r.data).recordType == "A" ]
# }

# output "a_records" {
#     value = [ for r in restapi_object.record: r if jsondecode(r.data).recordType == "CNAME" ]
# }