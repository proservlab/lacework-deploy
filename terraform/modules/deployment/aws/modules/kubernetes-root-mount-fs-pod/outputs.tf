locals {
  services = [
        {
            name = local.app_name
            namespace = local.app_namespace
            hostname = kubernetes_service_v1.this.status[0].load_balancer[0].ingress[0].hostname
            dynu_dns_name = var.enable_dynu_dns ? module.dns-records-service[local.app_name].dynu_dns_record.api_data.hostname : null
            ip = null
            port = kubernetes_service_v1.this.spec[0].port[0].port
        }
    ]
}

output "services" {
    value = local.services
}