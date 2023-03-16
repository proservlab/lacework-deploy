output "ssh_key_path" { value = module.compute.ssh_key_path }
output "public_ip" { value = module.compute.public_ip }

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
                # aks                           = module.gke
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

output "resource_group" {
    value = module.compute.resource_group
}