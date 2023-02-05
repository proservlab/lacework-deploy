output "id" {
    value = module.id.id
}

output "config" {
    value = {
        context = {
            workstation = {
                ip = module.workstation-external-ip.cidr
            }
            aws = {
                ec2                       = module.ec2
                eks                       = module.eks
            }
        }
    }
}

output "workstation_ip" {
    value = module.workstation-external-ip.cidr
}

output "infrastructure-config" {
    value = var.config
}