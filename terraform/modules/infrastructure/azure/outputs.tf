output "id" {
    value = module.id.id
}

output "config" {
    value = {
        context = {
            workstation = {
                ip = module.workstation-external-ip.cidr
            }
            azure = {
                compute                       = module.compute
                # aks                           = module.aks
                aks                           = null
                automation_account            = module.automation-account
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

output "public_resource_group" {
    value = length(module.compute) > 0 ? module.compute[0].public_resource_group : null
}

output "private_resource_group" {
    value = length(module.compute) > 0 ? module.compute[0].private_resource_group : null
}

output "ssh_key_path" {
    value = length(module.compute) > 0 ? module.compute[0].ssh_key_path : null
}

output "instances" {
    value = length(module.compute) > 0 ? module.compute[0].instances : null
}