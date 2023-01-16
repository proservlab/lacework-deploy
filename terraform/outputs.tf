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

output "target_kubernetes_services" {
  value = {
    voteapp = {
      voteapp_vote   = module.target-attacksurface.voteapp_vote_service
      voteapp_result   = module.target-attacksurface.voteapp_result_service
    },
    log4shellapp = {
      log4shellapp = module.target-attacksurface.log4shellapp_service
    },
    rdsapp = {
      rdsapp = module.target-attacksurface.rdsapp_service
    }
  }
}

output "attacker_kubernetes_services" {
  value = {
    voteapp = {
      voteapp_vote   = module.attacker-attacksurface.voteapp_vote_service
      voteapp_result   = module.attacker-attacksurface.voteapp_result_service
    },
    log4shellapp = {
      log4shellapp = module.attacker-attacksurface.log4shellapp_service
    },
    rdsapp = {
      rdsapp = module.attacker-attacksurface.rdsapp_service
    }
  }
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