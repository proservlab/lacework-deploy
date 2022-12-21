output "public_vpc" {
  value = var.enable_public_vpc == true ? module.public[0].vpc : null
}

output "public_subnet" {
  value = var.enable_public_vpc == true ? module.public[0].subnet : null
}

output "public_sg" {
  value = var.enable_public_vpc == true ? module.public[0].sg : null
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