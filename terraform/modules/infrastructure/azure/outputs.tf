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