output "log4shellapp_service" {
    value = kubernetes_service_v1.log4shell.status[0].load_balancer[0].ingress[0].hostname
}