module "dns-records-service" {
    for_each = { for service in local.services: service.name => service if var.enable_dynu_dns }
    source              = "../../../common/dynu-dns-record"
    dynu_api_key        = var.dynu_api_key
    dynu_dns_domain     = var.dynu_dns_domain


    record        = {   
        recordType      = "CNAME"
        recordName      = "${each.key}-${var.environment}-${var.deployment}"
        recordHostName  = "${each.key}.${coalesce(var.dynu_dns_domain, "unknown")}"
        recordValue     = each.value.hostname
        }
    depends_on = [ 
        kubernetes_service_v1.this 
    ]
}