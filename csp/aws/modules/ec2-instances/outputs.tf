output "instances" {
    value = module.instances
}

output "public_sg" {
    value = module.vpc.public_sg
}

output "private_sg" {
    value = module.vpc.private_sg
}