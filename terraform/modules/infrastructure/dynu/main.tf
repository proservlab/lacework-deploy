module "dns-records" {
  count           = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.dynu_dns.enabled == true ) ? 1 : 0
  source          = "./modules/dns_records"
  dynu_api_token  = var.dynu_api_token
  dynu_dns_domain = var.dynu_dns_domain
  records = var.records
}