output "aws-ec2" {
    value = try(module.aws-ec2[0], null)
}

output "aws-eks" {
    value = try(module.aws-eks[0], null)
}

output "aws-rds" {
    value = try(module.aws-rds[0], null)
}

output "workstation_cidr" {
    value = module.workstation-external-ip.cidr
}