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

output "private_vpc" {
  value = var.enable_private_vpc == true ? module.private[0].vpc : null
}

output "private_subnet" {
  value = var.enable_private_vpc == true ? module.private[0].subnet : null
}

output "private_sg" {
  value = var.enable_private_vpc == true ? module.private[0].sg : null
}

output "private_nat_gw" {
  value = var.enable_private_vpc == true ? module.private[0].nat_gateway : null
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

output "private_app_nat_gw" {
  value = var.enable_private_app_vpc == true ? module.private-app[0].nat_gateway : null
}