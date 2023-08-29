output "target_ssh_key" {
  value = module.target-azure-infrastructure.ssh_key_path
}

output "attacker_ssh_key" {
  value = module.attacker-azure-infrastructure.ssh_key_path
}

output "target-azure-instances" {
  sensitive = false
  value     = module.target-azure-infrastructure.instances
}

output "attacker-azure-instances" {
  sensitive = false
  value     = module.attacker-azure-infrastructure.instances
}