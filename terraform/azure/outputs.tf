locals {
  attacker-azure-instances = [
    for compute in try(module.azure-deployment.attacker-instances, []) : {
      id            = compute.id
      name          = compute.name
      role          = compute.role
      public        = compute.public
      public_ip     = compute.public_ip
      admin_user    = compute.admin_user
      ssh_key_path  = compute.ssh_key_path
      tags          = { for k, v in compute.tags : k => v if v != "false" }
      tenant        = var.attacker_azure_tenant
      subscription  = var.attacker_azure_subscription
      region        = var.attacker_azure_region
      dynu_dns_name = try(module.azure-deployment.attacker-dns-records[compute.name].dynu_dns_record.api_data.hostname, null)
    }
  ]

  target-azure-instances = [
    for compute in try(module.azure-deployment.target-instances, []) : {
      id            = compute.id
      name          = compute.name
      role          = compute.role
      public        = compute.public
      public_ip     = compute.public_ip
      admin_user    = compute.admin_user
      ssh_key_path  = compute.ssh_key_path
      tags          = { for k, v in compute.tags : k => v if v != "false" }
      tenant        = var.target_azure_tenant
      subscription  = var.target_azure_subscription
      region        = var.target_azure_region
      dynu_dns_name = try(module.azure-deployment.target-dns-records[compute.name].dynu_dns_record.api_datahostname, null)
    }
  ]
}

output "attacker-azure-instances" {
  value = local.attacker-azure-instances
}

output "target-azure-instances" {
  value = local.target-azure-instances
}

output "attacker-azure-k8s-services" {
  value = module.azure-deployment.attacker-k8s-services
}

output "target-azure-k8s-services" {
  value = module.azure-deployment.target-k8s-services
}