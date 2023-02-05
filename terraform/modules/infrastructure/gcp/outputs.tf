output "id" {
    value = module.id.id
}

output "config" {
    value = {
        context = {
            workstation = {
                ip = module.workstation-external-ip.cidr
            }
            gcp = {
                gce                       = module.gce
                gke                       = module.gke
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