locals {
  attacker-aws-instances = [
    for instance_name in try(keys(module.aws-deployment.attacker-instances), []) :
    {
      id            = module.aws-deployment.attacker-instances[instance_name].instance.id
      name          = module.aws-deployment.attacker-instances[instance_name].instance.tags["Name"]
      private_ip    = module.aws-deployment.attacker-instances[instance_name].instance.private_ip
      public_ip     = module.aws-deployment.attacker-instances[instance_name].instance.public_ip
      tags          = { for k, v in module.aws-deployment.attacker-instances[instance_name].instance.tags : k => v if v != "false" }
      profile       = var.attacker_aws_profile
      region        = var.attacker_aws_region
      dynu_dns_name = try(module.aws-deployment.attacker-dns-records[module.aws-deployment.attacker-instances[instance_name].instance.tags["Name"]].dynu_dns_record.api_data.hostname, null)
    }
  ]

  target-aws-instances = [
    for instance_name in try(keys(module.aws-deployment.target-instances), []) :
    {
      id            = module.aws-deployment.target-instances[instance_name].instance.id
      name          = module.aws-deployment.target-instances[instance_name].instance.tags["Name"]
      private_ip    = module.aws-deployment.target-instances[instance_name].instance.private_ip
      public_ip     = module.aws-deployment.target-instances[instance_name].instance.public_ip
      tags          = { for k, v in module.aws-deployment.target-instances[instance_name].instance.tags : k => v if v != "false" }
      profile       = var.target_aws_profile
      region        = var.target_aws_region
      dynu_dns_name = try(module.aws-deployment.target-dns-records[module.aws-deployment.target-instances[instance_name].instance.tags["Name"]].dynu_dns_record.api_data.hostname, null)
    }
  ]
}

output "attacker-aws-instances" {
  value = local.attacker-aws-instances
}

output "target-aws-instances" {
  value = local.target-aws-instances
}

output "attacker-aws-k8s-services" {
  value = module.aws-deployment.attacker-k8s-services
}

output "target-aws-k8s-services" {
  value = module.aws-deployment.target-k8s-services
}

output "attacker_private_nat_gw_ip" {
  value = module.aws-deployment.attacker_private_nat_gw_ip
}

output "attacker_private_app_nat_gw_ip" {
  value = module.aws-deployment.attacker_private_app_nat_gw_ip
}

output "target_private_nat_gw_ip" {
  value = module.aws-deployment.target_private_nat_gw_ip
}

output "target_private_app_nat_gw_ip" {
  value = module.aws-deployment.target_private_app_nat_gw_ip
}