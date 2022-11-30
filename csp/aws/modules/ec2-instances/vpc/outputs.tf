output "public_vpc" {
  value = enable_public_vpc == true ? module.public[0].vpc : {}
}

output "public_subnet" {
  value = enable_public_vpc == true ? module.public[0].subnet : {}
}

output "public_sg" {
  value = enable_public_vpc == true ? module.public[0].sg : {}
}

output "private_vpc" {
  value = enable_private_vpc == true ? module.private[0].vpc : {}
}

output "private_subnet" {
  value = enable_private_vpc == true ? module.private[0].subnet : {}
}

output "private_sg" {
  value = enable_private_vpc == true ? module.private[0].sg : {}
}