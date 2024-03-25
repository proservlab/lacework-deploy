output "attacker-instances" {
    value = module.aws-deployment.attacker-instances
}

output "attacker-dns-records" {
    value = module.aws-deployment.attacker-dns-records
}

output "target-instances" {
    value = module.aws-deployment.target-instances
}

output "target-dns-records" {
    value = module.aws-deployment.target-dns-records
}

output "attacker-k8s-services" {
    value = module.aws-deployment.attacker-k8s-service
}

output "target-k8s-services" {
    value = module.aws-deployment.target-k8s-service
}