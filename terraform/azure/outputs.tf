output "target_ssh_key" {
  value = module.target-azure-infrastructure.ssh_key_path
}

output "attacker_ssh_key" {
  value = module.attacker-azure-infrastructure.ssh_key_path
}

output "instances" {
  value = [for instance in module.target-azure-infrastructure.instances : {
    name       = instance.name
    public_ip  = instance.public_ip_address
    admin_user = instance.admin_username
  }]
}