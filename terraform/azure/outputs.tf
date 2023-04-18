output "target_ssh_key" {
  value = module.target-azure-infrastructure.ssh_key_path
}

output "attacker_ssh_key" {
  value = module.attacker-azure-infrastructure.ssh_key_path
}

output "instances" {
  sensitive = false
  value     = module.target-azure-infrastructure.instances
}