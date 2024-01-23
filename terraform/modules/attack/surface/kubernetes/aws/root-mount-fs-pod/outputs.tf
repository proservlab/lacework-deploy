output "id" {
    value = module.id.id
}

output "services" {
    value = [
        {
            name = local.app_name
            hostname = kubernetes_service_v1.this.status[0].load_balancer[0].ingress[0].hostname
            ip = null
            port = kubernetes_service_v1.this.spec[0].port[0].port
        }
    ]
}