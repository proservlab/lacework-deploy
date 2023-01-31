
output "target_dynu_records" {
  value = try(module.target-dynu-dns[0].records, [])
}

output "attacker_dynu_records" {
  value = try(module.attacker-dynu-dns[0].records, [])
}

output "target-aws-instances" {
  value = [
    for ec2 in can(length(module.target-aws-infrastructure.config.context.aws.ec2)) ? module.target-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : compute.instance.public_ip if lookup(compute.instance, "public_ip", "false") != "false"
    ]
  ]
}

output "attacker-aws-instances" {
  value = [
    for ec2 in can(length(module.attacker-aws-infrastructure.config.context.aws.ec2)) ? module.attacker-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : compute.instance.public_ip if lookup(compute.instance, "public_ip", "false") != "false"
    ]
  ]
}

output "target_kubernetes_services" {
  value = {
    voteapp = {
      voteapp_vote   = module.target-attacksurface.voteapp_vote_service
      voteapp_result = module.target-attacksurface.voteapp_result_service
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
      voteapp_result = module.attacker-attacksurface.voteapp_result_service
    },
    log4shellapp = {
      log4shellapp = module.attacker-attacksurface.log4shellapp_service
    },
    rdsapp = {
      rdsapp = module.attacker-attacksurface.rdsapp_service
    }
  }
}

# output "target-compromised-credentials" {
#   value = [for u, k in module.target-attacksurface.compromised_credentials : "${u}:${k.rendered}"]
# }

# output "gce" {
#   sensitive = true
#   value     = module.target-infrastructure.config.context.gcp.gce
# }