output "ec2-instances" {
  value = module.environment-proservlab.ec2-instances
}

output "attacker-instance-reverseshell" {
  value = module.environment-proservlab.attacker-instance-reverseshell
}

output "attacker-instance-http-listener" {
  value = module.environment-proservlab.attacker-instance-http-listener
}