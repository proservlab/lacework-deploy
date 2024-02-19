locals {
  dynu_api = "https://api.dynu.com/v2"
}

resource "restapi_object" "record" {
  path          = "/dns/${var.dynu_dns_domain_id}/record"
  destroy_data  = ""
  data          = jsonencode({
    nodeName    = var.record.recordName
    recordType  = var.record.recordType
    ttl         = "90"
    state       = "true"
    group       = ""
    host        = var.record.recordType == "CNAME" ? var.record.recordValue : null
    ipv4Address = var.record.recordType == "A" ? var.record.recordValue : null
  })
  id_attribute  = "id"
}