

output "instances" {
    value = module.instances
}

output "dns-records" {
    value = module.dns-records
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

output "public_app_network" {
    value = var.public_app_network
}

output "public_app_vpc" {
    value = module.vpc.public_app_vpc
}

output "public_app_sg" {
    value = module.vpc.public_app_sg
}

output "public_app_igw" {
    value = module.vpc.public_app_igw
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

output "private_nat_gw_ip" {
    value = module.vpc.private_nat_gw_ip
}

output "private_app_network" {
    value = var.private_app_network
}

output "private_app_vpc" {
    value = module.vpc.private_app_vpc
}

output "private_app_sg" {
    value = module.vpc.private_app_sg
}

output "private_app_nat_gw_ip" {
    value = module.vpc.private_app_nat_gw_ip
}

output "ec2_instance_role" {
    value = module.ssm_profile.ec2-instance-role
}

output "ec2_instance_app_role" {
    value = module.ssm_app_profile.ec2-instance-role
}

output "public_instance_cout" {
    value = local.public_instance_count
}

output "public_app_instance_count" {
    value = local.public_app_instance_count
}

output "private_instance_count" {
    value = local.private_instance_count
}

output "private_app_instance_count" {
    value = local.private_app_instance_count
}


