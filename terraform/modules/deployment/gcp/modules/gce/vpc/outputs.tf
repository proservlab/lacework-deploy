output "public_network" {
  value = var.enable_public_vpc == true && can(module.public[0].network) ? module.public[0].network : null
}

output "public_subnetwork" {
  value = var.enable_public_vpc == true && can(module.public[0].subnetwork) ? module.public[0].subnetwork : null
}

output "public_app_network" {
  value = var.enable_public_vpc == true && can(module.public-app[0].network) ? module.public-app[0].network : null
}

output "public_app_subnetwork" {
  value = var.enable_public_vpc == true && can(module.public-app[0].subnetwork) ? module.public-app[0].subnetwork : null
}

output "private_network" {
  value = var.enable_private_vpc == true && can(module.private[0].network) ? module.private[0].network : null
}

output "private_subnetwork" {
  value = var.enable_private_vpc == true && can(module.private[0].subnetwork)  ? module.private[0].subnetwork : null
}

output "private_app_network" {
  value = var.enable_private_vpc == true && can(module.private-app[0].network) ? module.private-app[0].network : null
}

output "private_app_subnetwork" {
  value = var.enable_private_vpc == true && can(module.private-app[0].subnetwork) ? module.private-app[0].subnetwork : null
}