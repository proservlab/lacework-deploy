output "id" {
    value = module.id.id
}
output "log4shellapp_service" {
    value = kubernetes_service_v1.log4shell.status[0].load_balancer[0].ingress[0].hostname
}

output "log4shellapp_service_port" {
    value = kubernetes_service_v1.log4shell.spec[0].port[0].port
}


