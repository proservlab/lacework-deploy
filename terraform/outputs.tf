output "test" {
  sensitive = true
  value     = module.target-gcp-infrastructure.config
}

output "target_dynu_records" {
  value = try(module.target-dynu-dns-records.records, [])
}

output "attacker_dynu_records" {
  value = try(module.attacker-dynu-dns-records.records, [])
}

output "target-aws-instances" {
  value = [
    for ec2 in can(length(module.target-aws-infrastructure.config.context.aws.ec2)) ? module.target-aws-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : compute.instance.public_ip if lookup(compute.instance, "public_ip", "false") != "false"
    ]
  ]
}

output "target-gcp-instances" {
  value = [
    for gce in can(length(module.target-gcp-infrastructure.config.context.gcp.gce)) ? module.target-gcp-infrastructure.config.context.gcp.gce : [] :
    [
      for compute in gce.instances : compute.instances.network_interface[0].access_config[0].nat_ip if lookup(try(compute.instances.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
    ]
  ]
}

output "attacker-aws-instances" {
  value = [
    for ec2 in can(length(module.attacker-aws-infrastructure.config.context.aws.ec2)) ? module.attacker-aws-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : compute.instance.public_ip if lookup(compute.instance, "public_ip", "false") != "false"
    ]
  ]
}

output "attacker-gcp-instances" {
  value = [
    for gce in can(length(module.attacker-gcp-infrastructure.config.context.gcp.gce)) ? module.attacker-gcp-infrastructure.config.context.gcp.gce : [] :
    [
      for compute in gce.instances : compute.instances.network_interface[0].access_config[0].nat_ip if lookup(try(compute.instances.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
    ]
  ]
}

# output "target_aws_kubernetes_services" {
#   value = {
#     voteapp = {
#       voteapp_vote   = module.target-aws-attacksurface.voteapp_vote_service
#       voteapp_result = module.target-aws-attacksurface.voteapp_result_service
#     },
#     log4shellapp = {
#       log4shellapp = module.target-aws-attacksurface.log4shellapp_service
#     },
#     rdsapp = {
#       rdsapp = module.target-aws-attacksurface.rdsapp_service
#     }
#   }
# }

# output "attacker_aws_kubernetes_services" {
#   value = {
#     voteapp = {
#       voteapp_vote   = module.attacker-aws-attacksurface.voteapp_vote_service
#       voteapp_result = module.attacker-aws-attacksurface.voteapp_result_service
#     },
#     log4shellapp = {
#       log4shellapp = module.attacker-aws-attacksurface.log4shellapp_service
#     },
#     rdsapp = {
#       rdsapp = module.attacker-aws-attacksurface.rdsapp_service
#     }
#   }
# }

# output "target-compromised-credentials" {
#   value = [for u, k in module.target-aws-attacksurface.compromised_credentials : "${u}:${k.rendered}"]
# }

# output "gce" {
#   sensitive = true
#   value     = module.target-aws-infrastructure.config.context.gcp.gce
# }