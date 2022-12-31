output "target-instances" {
  value = [
    for ec2 in can(length(module.target-infrastructure.config.context.aws.ec2)) ? module.target-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : compute.instance.public_ip if lookup(compute.instance, "public_ip", "false") != "false"
    ]
  ]
}

output "attacker-instances" {
  value = [
    for ec2 in can(length(module.attacker-infrastructure.config.context.aws.ec2)) ? module.attacker-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : compute.instance.public_ip if lookup(compute.instance, "public_ip", "false") != "false"
    ]
  ]
}

# output "ec2-instances" {
#   value = {
#     target   = module.target.ec2-instances
#     attacker = module.attacker.ec2-instances
#   }
# }

# output "simulation_attacker_instances" {
#   value = local.attacker
# }

# output "simulation_target_instances" {
#   value = local.target
# }