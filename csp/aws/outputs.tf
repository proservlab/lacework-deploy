# output "ec2-instances" {
#   value = {
#     target   = module.target.ec2-instances
#     attacker = module.attacker.ec2-instances
#   }
# }

output "simulation_attacker_instances" {
  value = local.attacker
}

output "simulation_target_instances" {
  value = local.target
}

output "keys" {
  value     = aws_iam_access_key.target_iam_users_access_key
  sensitive = true
}