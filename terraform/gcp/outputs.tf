

# output "target-compromised-credentials" {
#   value = [for u, k in module.target-gcp-attacksurface.compromised_credentials : "${u}:${k.rendered}"]
# }

# output "target-gcp-instances" {
#   value = [
#     for gcp in can(length(module.target-gcp-infrastructure.config.context.gcp.gce)) ? module.target-gcp-infrastructure.config.context.gcp.gce : [] :
#     [
#       for compute in gce.instances : {
#         id         = compute.instance.id
#         name       = compute.instance.tags["Name"]
#         private_ip = compute.instance.private_ip
#         public_ip  = compute.instance.public_ip
#         tags       = { for k, v in compute.instance.tags : k => v if v != "false" }
#       }
#     ]
#   ]
# }

# output "attacker-gcp-instances" {
#   value = [
#     for gce in can(length(module.attacker-gcp-infrastructure.config.context.gcp.gce)) ? module.attacker-gcp-infrastructure.config.context.gcp.gce : [] :
#     [
#       for compute in gce.instances : {
#         id        = compute.instance.id
#         name      = compute.instance.tags["Name"]
#         public_ip = compute.instance.public_ip
#         tags = [
#           for k, v in compute.instance.tags : { "${k}" = v } if v != "false"
#         ]
#       }
#     ]
#   ]
# }

# output "gce" {
#   sensitive = true
#   value     = module.target-aws-infrastructure.config.context.gcp.gce
# }