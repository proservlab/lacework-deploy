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