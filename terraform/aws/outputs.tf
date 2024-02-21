
# output "target-aws-instances" {
#   value = [
#     for ec2 in can(length(module.target-aws-infrastructure.config.context.aws.ec2)) ? module.target-aws-infrastructure.config.context.aws.ec2 : [] :
#     [
#       for compute in ec2.instances : {
#         id         = compute.instance.id
#         name       = compute.instance.tags["Name"]
#         private_ip = compute.instance.private_ip
#         public_ip  = compute.instance.public_ip
#         tags       = { for k, v in compute.instance.tags : k => v if v != "false" }
#         profile    = var.target_aws_profile
#         region     = var.target_aws_region
#       }
#     ]
#   ][0]
# }

# output "attacker-aws-instances" {
#   value = [
#     for ec2 in can(length(module.attacker-aws-infrastructure.config.context.aws.ec2)) ? module.attacker-aws-infrastructure.config.context.aws.ec2 : [] :
#     [
#       for compute in ec2.instances : {
#         id        = compute.instance.id
#         name      = compute.instance.tags["Name"]
#         public_ip = compute.instance.public_ip
#         tags      = { for k, v in compute.instance.tags : k => v if v != "false" }
#         profile   = var.attacker_aws_profile
#         region    = var.attacker_aws_region
#       }
#     ]
#   ][0]
# }

# output "target_aws_kubernetes_services" {
#   value = {
#     vulnerable = module.target-aws-attacksurface.kubernetes.vulnerable
#   }
# }

# output "attacker_aws_kubernetes_services" {
#   value = {
#     voteapp = {
#       voteapp_vote   = module.attacker-aws-attacksurface.voteapp_vote_service
#       voteapp_result = module.attacker-aws-attacksurface.voteapp_result_service
#     },
#     log4j-app = {
#       log4j-app = module.attacker-aws-attacksurface.log4j_app_service
#     },
#     rdsapp = {
#       rdsapp = module.attacker-aws-attacksurface.rdsapp_service
#     }
#   }
# }

# output "target-compromised-credentials" {
#   value = [for u, k in module.target-aws-attacksurface.compromised_credentials : "${u}:${k.rendered}"]
# }