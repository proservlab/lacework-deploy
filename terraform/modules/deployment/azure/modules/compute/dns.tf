################################
# DYNU DNS - DEFAULT AND APP
################################

module "dns-records" {
    for_each              = { for instance in local.public_compute_instances: instance.name => instance }
    source              = "../../../common/dynu-dns-record"
    dynu_api_key        = var.dynu_api_key
    dynu_dns_domain     = var.dynu_dns_domain
    
    record        = {
            recordType     = "A"
            recordName     = "${each.key}"
            recordHostName = "${each.key}.${coalesce(var.dynu_dns_domain, "unknown")}"
            recordValue    = each.value.public_ip
        }
    
    depends_on = [
        azurerm_linux_virtual_machine.instances,
        azurerm_linux_virtual_machine.instances-app 
    ]
}