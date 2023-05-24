output "id" {
    value = module.id.id
}

output "service" {
    value = kubernetes_service_v1.this.status[0].load_balancer[0].ingress[0].hostname
}

output "service_port" {
    value = kubernetes_service_v1.this.spec[0].port[0].port
}