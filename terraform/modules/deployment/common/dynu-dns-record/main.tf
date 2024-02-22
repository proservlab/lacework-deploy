locals {
  dynu_api = "https://api.dynu.com/v2/dns"
  dynu_domains_response = jsondecode(data.http.dynu_domain_id.response_body)
  dynu_domain_id = one([ for domain in local.dynu_domains_response["domains"]: domain.id if domain.name == var.dynu_dns_domain  ])
  dynu_records_response  = jsondecode(data.http.dynu_records.response_body)
}

data "http" "dynu_domain_id" {
  url = local.dynu_api
  method = "GET"

  # Optional request headers
  request_headers = {
    API-Key = var.dynu_api_key
    Accept = "application/json"
    Content-Type = "application/json"
  }

  retry {
    attempts = 3
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code) && try(length(self.response_body)>0, false)
      error_message = "Status code invalid"
    }
  }
}

data "http" "dynu_records" {
  url = "${local.dynu_api}/${local.dynu_domain_id}/record"
  method = "GET"

  # Optional request headers
  request_headers = {
    API-Key = var.dynu_api_key
    Accept = "application/json"
    Content-Type = "application/json"
  }

  retry {
    attempts = 3
  }

  lifecycle {
    postcondition {
      condition     = contains([200], self.status_code) && try(length(self.response_body)>0, false)
      error_message = "Status code invalid"
    }
  }
}

resource "restapi_object" "record" {
  path          = "/dns/${local.dynu_domain_id}/record"
  destroy_data  = ""
  create_method = "POST"
  destroy_method = "DELETE"
  update_method = "POST"

  data          = var.record.recordType == "CNAME" ? jsonencode({
    nodeName    = var.record.recordName
    recordType  = var.record.recordType
    ttl         = 90
    state       = true
    group       = ""
    host        = var.record.recordValue
  }) : jsonencode({
    nodeName    = var.record.recordName
    recordType  = var.record.recordType
    ttl         = 90
    state       = true
    group       = ""
    ipv4Address = var.record.recordValue
  })
  id_attribute  = "id"

  force_new = [ 
    var.record.recordName,
    var.record.recordValue,
    var.record.recordType
  ]

  depends_on = [ data.http.dynu_domain_id, data.http.dynu_records ]
}