output "vpc" {
    value = module.vpc
}

output "instances" {
    sensitive = false
    value = module.instances
}
output "public_network" {
    value = var.public_network
}

output "public_subnetwork" {
    value = var.public_subnetwork
}

output "public_app_network" {
    value = var.public_app_network
}

output "public_app_subnetwork" {
    value = var.public_app_subnetwork
}

output "private_network" {
    value = var.private_network
}

output "private_subnetwork" {
    value = var.private_subnetwork
}

output "private_app_network" {
    value = var.private_app_network
}

output "private_app_subnetwork" {
    value = var.private_app_subnetwork
}

output "public_service_account_email" {
    value = module.public_service_account.service_account_email
}

output "public_app_service_account_email" {
    value = module.public_app_service_account.service_account_email
}

output "private_service_account_email" {
    value = module.private_service_account.service_account_email
}

output "private_app_service_account_email" {
    value = module.private_app_service_account.service_account_email
}