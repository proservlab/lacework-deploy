module "dns-records" {
  for_each = { for instance in local.public_compute_instances: lookup(instance.tags, "Name", "unknown") => instance }
  source          = "../../../dynu/dns_record"
  dynu_dns_domain_id = var.dynu_dns_domain_id  
  dynu_dns_domain    = var.dynu_dns_domain

  record        = {
        recordType     = "A"
        recordName     = "${each.key}"
        recordHostName = "${each.key}.${coalesce(var.dynu_dns_domain, "unknown")}"
        recordValue    = each.value.public_ip
      }
}