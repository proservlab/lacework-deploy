locals {
  dynu_api = "https://api.dynu.com/v2/dns"
  dynu_domains_response = jsondecode(data.http.dynu_domain_id.request_body)
  dynu_domain_id = one([ for domain in local.dynu_domains_response["domains"]: domain.id if domain.name == var.dynu_dns_domain  ])
}

data "http" "dynu_domain_id" {
  url = local.dynu_api

  # Optional request headers
  request_headers = {
    API-Key = var.dynu_api_key
    Accept = "application/json"
    Content-Type = "application/json"
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code)
      error_message = "Status code invalid"
    }
  }
}

# data "restapi_object" "domain" {
#   path         = "/v2/dns"
#   search_key   = "name"
#   search_value = var.dynu_dns_domain
#   id_attribute = "id"
#   results_key = "domains"
# }

resource "restapi_object" "record" {
  path          = "/v2/dns/${local.dynu_domain_id}/record"
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