output "id" {
    value = module.id.id
}

output "rdsapp_service" {
    value = kubernetes_service_v1.rdsapp.status[0].load_balancer[0].ingress[0].hostname
}

output "rdsapp_service_port" {
    value = kubernetes_service_v1.rdsapp.spec[0].port[0].port
}