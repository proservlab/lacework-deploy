output "id" {
    value = module.id.id
}

output "services" {
    value = [
        {
            name = local.app_name
            namespace = local.app_namespace
            hostname = kubernetes_service_v1.this.status[0].load_balancer[0].ingress[0].hostname
            ip = null
            port = kubernetes_service_v1.this.spec[0].port[0].port
        }
    ]
}

output "service_name" {
    value = local.app_name
}

output "service" {
    value = kubernetes_service_v1.this.status[0].load_balancer[0].ingress[0].hostname
}

output "service_port" {
    value = kubernetes_service_v1.this.spec[0].port[0].port
}


