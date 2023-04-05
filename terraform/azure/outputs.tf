output "ssh_key" {
  value = module.target-azure-infrastructure.ssh_key_path
}
output "instances" {
  value = [for instance in module.target-azure-infrastructure.instances : {
    name              = instance.name
    public_ip = instance.public_ip_address
  }]
}

# output "environment" {
#   value = {
#     # context
#     scenario   = var.scenario
#     deployment = var.deployment

#     # aws
#     attacker_aws_profile = can(length(var.attacker_aws_profile)) ? var.attacker_aws_profile : ""
#     attacker_aws_region  = var.attacker_aws_region
#     target_aws_profile   = can(length(var.target_aws_profile)) ? var.target_aws_profile : ""
#     target_aws_region    = var.target_aws_region

#     # gcp
#     attacker_gcp_project          = var.attacker_gcp_project
#     attacker_gcp_region           = var.attacker_gcp_region
#     attacker_gcp_lacework_project = var.attacker_gcp_lacework_project
#     target_gcp_project            = var.target_gcp_project
#     target_gcp_region             = var.target_gcp_region
#     target_gcp_lacework_project   = var.target_gcp_lacework_project

#     # lacework
#     lacework_server_url   = var.lacework_server_url
#     lacework_account_name = var.lacework_account_name
#     lacework_profile      = var.lacework_profile
#     syscall_config_path   = abspath("${path.module}/scenarios/${var.scenario}/target/resources/syscall_config.yaml")
#   }
# }

# output "attacker" {
#   value = module.attacker-infrastructure-context.config
# }

# output "target" {
#   value = module.target-infrastructure-context.config
# }

# output "target_dynu_records" {
#   value = (module.target-infrastructure-context.config.context.dynu_dns.enabled == true) ? try(module.target-dynu-dns-records.records, []) : []
# }

# output "attacker_dynu_records" {
#   value = (module.attacker-infrastructure-context.config.context.dynu_dns.enabled == true) ? try(module.attacker-dynu-dns-records.records, []) : []
# }

# output "target-aws-instances" {
#   value = [
#     for ec2 in can(length(module.target-aws-infrastructure.config.context.aws.ec2)) ? module.target-aws-infrastructure.config.context.aws.ec2 : [] :
#     [
#       for compute in ec2.instances : compute.instance.public_ip if lookup(compute.instance, "public_ip", "false") != "false"
#     ]
#   ]
# }

# output "target-gcp-instances" {
#   value = [
#     for gce in can(length(module.target-gcp-infrastructure.config.context.gcp.gce)) ? module.target-gcp-infrastructure.config.context.gcp.gce : [] :
#     [
#       for compute in gce.instances : compute.instance.network_interface[0].access_config[0].nat_ip if lookup(try(compute.instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
#     ]
#   ]
# }

# output "attacker-aws-instances" {
#   value = [
#     for ec2 in can(length(module.attacker-aws-infrastructure.config.context.aws.ec2)) ? module.attacker-aws-infrastructure.config.context.aws.ec2 : [] :
#     [
#       for compute in ec2.instances : compute.instance.public_ip if lookup(compute.instance, "public_ip", "false") != "false"
#     ]
#   ]
# }

# output "attacker-gcp-instances" {
#   value = [
#     for gce in can(length(module.attacker-gcp-infrastructure.config.context.gcp.gce)) ? module.attacker-gcp-infrastructure.config.context.gcp.gce : [] :
#     [
#       for compute in gce.instances : compute.instance.network_interface[0].access_config[0].nat_ip if lookup(try(compute.instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
#     ]
#   ]
# }

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