output "rdsapp_service" {
    value = kubernetes_service_v1.rdsapp.status[0].load_balancer[0].ingress[0].hostname
}