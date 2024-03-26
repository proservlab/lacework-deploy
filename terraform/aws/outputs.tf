locals {
    attacker-aws-instances = one([
      for compute in try(module.aws-deployment.attacker-instances, []) : {
        id         = compute.instance.id
        name       = compute.instance.tags["Name"]
        private_ip = compute.instance.private_ip
        public_ip  = compute.instance.public_ip
        tags       = { for k, v in compute.instance.tags : k => v if v != "false" }
        profile    = var.attacker_aws_profile
        region     = var.attacker_aws_region
        dynu_dns_name = try(module.aws-deployment.attacker-dns-records[compute.instance.tags["Name"]].dynu_dns_record.hostname, null)
      }
    ])

    target-aws-instances = one([
      for compute in try(module.aws-deployment.target-instances, []) : {
        id         = compute.instance.id
        name       = compute.instance.tags["Name"]
        private_ip = compute.instance.private_ip
        public_ip  = compute.instance.public_ip
        tags       = { for k, v in compute.instance.tags : k => v if v != "false" }
        profile    = var.target_aws_profile
        region     = var.target_aws_region
        dynu_dns_name = try(module.aws-deployment.target-dns-records[compute.instance.tags["Name"]].dynu_dns_record.hostname, null)
      }
    ])
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