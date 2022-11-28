output "ec2-instances" {
    value = module.ec2-instances
}

output "eks" {
    value = module.eks
}

output "public_sg" {
    value = length(module.ec2-instances) > 0 ? module.ec2-instances[0].public_sg : null
}

output "private_sg" {
    value = length(module.ec2-instances) > 0 ? module.ec2-instances[0].private_sg : null
}