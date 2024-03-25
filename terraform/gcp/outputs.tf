output "attacker-instances" {
    value = module.gcp-deployment.attacker-instances
}

output "attacker-dns-records" {
    value = module.gcp-deployment.attacker-dns-records
}

output "target-instances" {
    value = module.gcp-deployment.target-instances
}

output "target-dns-records" {
    value = module.gcp-deployment.target-dns-records
}

output "attacker-k8s-services" {
    value = module.gcp-deployment.attacker-k8s-service
}

output "target-k8s-services" {
    value = module.gcp-deployment.target-k8s-service
}