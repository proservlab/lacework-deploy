
output "target-aws-instances" {
  value = [
    for ec2 in can(length(module.target-aws-infrastructure.config.context.aws.ec2)) ? module.target-aws-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : {
        id         = compute.instance.id
        name       = compute.instance.tags["Name"]
        private_ip = compute.instance.private_ip
        public_ip  = compute.instance.public_ip
        tags = [
          for k, v in compute.instance.tags : { "${k}" = v } if v != "false"
        ]
      }
    ]
  ]
}

output "attacker-aws-instances" {
  value = [
    for ec2 in can(length(module.attacker-aws-infrastructure.config.context.aws.ec2)) ? module.attacker-aws-infrastructure.config.context.aws.ec2 : [] :
    [
      for compute in ec2.instances : {
        id        = compute.instance.id
        name      = compute.instance.tags["Name"]
        public_ip = compute.instance.public_ip
        tags = [
          for k, v in compute.instance.tags : { "${k}" = v } if v != "false"
        ]
      }
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