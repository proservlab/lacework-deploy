output "public_vpc" {
  value = var.enable_public_vpc == true ? module.public[0].vpc : null
}

output "public_subnet" {
  value = var.enable_public_vpc == true ? module.public[0].subnet : null
}

output "public_sg" {
  value = var.enable_public_vpc == true ? module.public[0].sg : null
}

output "public_igw" {
  value = var.enable_public_vpc == true ? module.public[0].igw : null
}

output "public_vpc_endpoint_security_group" {
  value = var.enable_public_vpc == true ? module.public[0].vpc_endpoint_security_group : null
}

output "public_app_vpc" {
  value = var.enable_public_app_vpc == true ? module.public-app[0].vpc : null
}

output "public_app_subnet" {
  value = var.enable_public_app_vpc == true ? module.public-app[0].subnet : null
}

output "public_app_sg" {
  value = var.enable_public_app_vpc == true ? module.public-app[0].sg : null
}

output "public_app_igw" {
  value = var.enable_public_app_vpc == true ? module.public-app[0].igw : null
}

output "public_app_vpc_endpoint_security_group" {
  value = var.enable_public_app_vpc == true ? module.public-app[0].vpc_endpoint_security_group : null
}

output "private_vpc" {
  value = var.enable_private_vpc == true ? module.private[0].vpc : null
}

output "private_subnet" {
  value = var.enable_private_vpc == true ? module.private[0].subnet : null
}

output "private_sg" {
  value = var.enable_private_vpc == true ? module.private[0].sg : null
}

output "private_nat_gw_ip" {
  value = var.enable_private_vpc == true ? module.private[0].nat_gateway_ip : null
}

output "private_vpc_endpoint_security_group" {
  value = var.enable_private_vpc == true ? module.private[0].vpc_endpoint_security_group : null
}

output "private_app_vpc" {
  value = var.enable_private_app_vpc == true ? module.private-app[0].vpc : null
}

output "private_app_subnet" {
  value = var.enable_private_app_vpc == true ? module.private-app[0].subnet : null
}

output "private_app_sg" {
  value = var.enable_private_app_vpc == true ? module.private-app[0].sg : null
}

output "private_app_nat_gw_ip" {
  value = var.enable_private_app_vpc == true ? module.private-app[0].nat_gateway_ip : null
}

output "private_app_vpc_endpoint_security_group" {
  value = var.enable_private_app_vpc == true ? module.private-app[0].vpc_endpoint_security_group : null
}