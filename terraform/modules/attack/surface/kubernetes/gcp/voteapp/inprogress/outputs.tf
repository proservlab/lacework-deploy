output "id" {
    value = module.id.id
}

output "vote_service" {
    value = kubernetes_service_v1.vote.status[0].load_balancer[0].ingress[0].hostname
}

output "vote_service_port" {
    value = kubernetes_service_v1.vote.spec[0].port[0].port
}

output "result_service" {
    value = kubernetes_service_v1.result.status[0].load_balancer[0].ingress[0].hostname
}

output "result_service_port" {
    value = kubernetes_service_v1.result.spec[0].port[0].port
}