locals {
    attacker-gcp-instances = nonsensitive([
      for compute in try(module.gcp-deployment.attacker-instances, []) : {
        id         = compute.instance.id
        name       = compute.instance.labels.name
        private_ip = compute.instance.network_interface.0.network_ip
        public_ip  = compute.instance.network_interface.0.access_config.0.nat_ip
        labels     = { for k, v in compute.instance.labels : k => v if v != "false" }
        project_id = var.attacker_gcp_project
        region     = var.attacker_gcp_region
        dynu_dns_name = try(module.gcp-deployment.attacker-dns-records[compute.instance.labels.name].dynu_dns_record.hostname, null)
      }
    ])

    target-gcp-instances = nonsensitive([
      for compute in try(module.gcp-deployment.target-instances, []) : {
        id         = compute.instance.id
        name       = compute.instance.labels.name
        private_ip = compute.instance.network_interface.0.network_ip
        public_ip  = compute.instance.network_interface.0.access_config.0.nat_ip
        labels     = { for k, v in compute.instance.labels : k => v if v != "false" }
        project_id = var.target_gcp_project
        region     = var.target_gcp_region
        dynu_dns_name = try(module.gcp-deployment.target-dns-records[compute.instance.labels.name].dynu_dns_record.hostname, null)
      }
    ])
}

output "attacker-gcp-instances" {
    value = local.attacker-gcp-instances
}

output "target-gcp-instances" {
    value = local.target-gcp-instances
}

output "attacker-gcp-k8s-services" {
    value = module.gcp-deployment.attacker-k8s-services
}

output "target-gcp-k8s-services" {
    value = module.gcp-deployment.target-k8s-services
}