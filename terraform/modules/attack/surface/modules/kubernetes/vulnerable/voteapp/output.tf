output "vote_service" {
    value = kubernetes_service_v1.vote.status[0].load_balancer[0].ingress[0].hostname
}

output "result_service" {
    value = kubernetes_service_v1.vote.status[0].load_balancer[0].ingress[0].hostname
}