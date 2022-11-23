output "ec2-instances" {
    value = module.ec2-instances
}

output "attacker-instance" {
    value = local.attacker_instance
}

output "eks" {
    value = module.eks
}