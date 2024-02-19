locals {
  dynu_api = "https://api.dynu.com/v2"
}

data "restapi_object" "domain" {
  path         = "/dns"
  search_key   = "name"
  search_value = "attacker-hub.freeddns.org"
  id_attribute = "id"
  results_key = "domains"
}

resource "restapi_object" "record" {
  path          = "/dns/${data.restapi_object.domain.id}/record"
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