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

output "resource_group" {
    value = module.resource_group
}

output "ssh_key_path" {
    value = length(module.compute) > 0 ? module.compute[0].ssh_key_path : null
}

output "instances" {
    value = length(module.compute) > 0 ? module.compute[0].instances : null
}