locals {
  services = [
        {
            name = local.app_name
            namespace = local.app_namespace
            hostname = kubernetes_service_v1.this.status[0].load_balancer[0].ingress[0].hostname
            ip = null
            port = kubernetes_service_v1.this.spec[0].port[0].port
        }
    ]
}

output "services" {
    value = local.services
}