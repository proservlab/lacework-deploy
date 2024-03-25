output "attacker-instances" {
  value = module.azure-deployment.attacker-instances
}

output "attacker-dns-records" {
  value = module.azure-deployment.attacker-dns-records
}

output "target-instances" {
  value = module.azure-deployment.target-instances
}

output "target-dns-records" {
  value = module.azure-deployment.target-dns-records
}

output "attacker-k8s-services" {
  value = module.azure-deployment.attacker-k8s-service
}

output "target-k8s-services" {
  value = module.azure-deployment.target-k8s-service
}