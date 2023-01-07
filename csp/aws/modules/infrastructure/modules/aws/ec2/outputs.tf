output "instances" {
    value = module.instances
}

output "public_network" {
    value = var.public_network
}

output "public_vpc" {
    value = module.vpc.public_vpc
}

output "public_sg" {
    value = module.vpc.public_sg
}

output "public_igw" {
    value = module.vpc.public_igw
}

output "private_network" {
    value = var.private_network
}

output "private_vpc" {
    value = module.vpc.private_vpc
}

output "private_sg" {
    value = module.vpc.private_sg
}