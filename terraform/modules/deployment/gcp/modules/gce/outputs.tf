output "vpc" {
    value = module.vpc
}

output "instances" {
    sensitive = false
    value = module.instances
}

output "dns-records" {
    value = module.dns-records
}

output "public_network" {
    value = module.vpc.public_network
}

output "public_subnetwork" {
    value = module.vpc.public_subnetwork
}

output "public_app_network" {
    value = module.vpc.public_app_network
}

output "public_app_subnetwork" {
    value = module.vpc.public_app_subnetwork
}

output "private_network" {
    value = module.vpc.private_network
}

output "private_subnetwork" {
    value = module.vpc.private_subnetwork
}

output "private_app_network" {
    value = module.vpc.private_app_network
}

output "private_app_subnetwork" {
    value = module.vpc.private_app_subnetwork
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