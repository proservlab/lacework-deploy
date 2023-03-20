locals {
  dynu_api = "https://api.dynu.com/v2"
}

data "restapi_object" "domain" {
  path         = "/dns"
  search_key   = "name"
  search_value = var.dynu_dns_domain
  id_attribute = "id"
  results_key = "domains"
}

resource "restapi_object" "record" {
  for_each = { for i in var.records: i.recordName => i }

  path          = "/dns/${data.restapi_object.domain.id}/record"
  destroy_data  = ""
  data          = jsonencode({
    nodeName    = each.key
    recordType  = upper(each.value.recordType)
    ttl         = "90"
    state       = "true"
    group       = ""
    host        = each.value.recordType == "cname" ? each.value.recordValue : null
    ipv4Address = each.value.recordType == "a" ? each.value.recordValue : null
  })
  id_attribute  = "id"
}