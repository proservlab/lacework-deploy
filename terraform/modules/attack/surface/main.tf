# merge and validate configuration
locals {
  config = var.config

  workstation_ips = [var.infrastructure.deployed_state.target.context.workstation.ip]

  attacker_eks = can(length(var.infrastructure.deployed_state.attacker.context.aws.eks)) ? var.infrastructure.deployed_state.attacker.context.aws.eks : []
  attacker_ec2 = can(length(var.infrastructure.deployed_state.attacker.context.aws.ec2)) ? var.infrastructure.deployed_state.attacker.context.aws.ec2 : []
  attacker_eks_trusted_ips = [ 
      for cluster in local.attacker_eks: "${cluster.cluster_nat_public_ip}/32" 
    ]
  attacker_ec2_trusted_ips = flatten([ 
      for ec2 in local.attacker_ec2: 
        [
          for compute in ec2.instances: "${compute.instance.public_ip}/32" if lookup(compute.instance, "public_ip", "false") != "false"
        ]
    ])
  
  target_eks = can(length(var.infrastructure.deployed_state.target.context.aws.eks)) ? var.infrastructure.deployed_state.target.context.aws.eks : []
  target_ec2 = can(length(var.infrastructure.deployed_state.target.context.aws.ec2)) ? var.infrastructure.deployed_state.target.context.aws.ec2 : []
  target_eks_trusted_ips = [ 
        for cluster in local.target_eks: "${cluster.cluster_nat_public_ip}/32" 
      ]
  target_ec2_trusted_ips = flatten([ 
      for ec2 in local.target_ec2: 
      [
        for compute in ec2.instances: "${compute.instance.public_ip}/32" if lookup(compute.instance.tags_all, "public_ip", "false") != "false"
      ] 
    ])
}

#########################
# AWS IAM
##########################

# create iam users
module "iam" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.aws.iam.enabled == true ) ? 1 : 0
  source      = "./modules/aws/iam"
  environment = var.infrastructure.config.context.global.environment
  deployment        = var.infrastructure.config.context.global.deployment
  region = var.infrastructure.config.context.aws.region

  user_policies = jsondecode(file(var.config.context.aws.iam.user_policies_path))
  users = jsondecode(file(var.config.context.aws.iam.users_path))
}

#########################
# AWS EC2 SECURITY GROUP
##########################

# append ingress rules
module "ec2-add-trusted-ingress" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? length(var.config.context.aws.ec2.add_trusted_ingress.security_group_ids) : 0
  source        = "./modules/aws/ec2/add-trusted-ingress"
  environment   = var.infrastructure.config.context.global.environment
  deployment    = var.infrastructure.config.context.global.deployment
  
  security_group_id = var.config.context.aws.ec2.add_trusted_ingress.security_group_ids[count.index]
  trusted_attacker_source   = var.config.context.aws.ec2.add_trusted_ingress.trust_attacker_source ? flatten([
      local.attacker_eks_trusted_ips,
      local.attacker_ec2_trusted_ips
    ]) : []
  trusted_target_source   = var.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
      local.target_eks_trusted_ips,
      local.target_ec2_trusted_ips
    ]) : []
  trusted_workstation_source    = local.workstation_ips
  trusted_tcp_ports             = var.config.context.aws.ec2.add_trusted_ingress.trusted_tcp_ports
}

#########################
# AWS SSM
# ssm tag-based surface config
##########################

module "ssh-keys" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/aws/ssm/ec2/ssh-keys"
  environment = var.infrastructure.config.context.global.environment
  deployment  = var.infrastructure.config.context.global.deployment
}

module "vulnerable-docker-log4shellspp" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.aws.ssm.vulnerable.docker.log4shellapp.enabled == true ) ? 1 : 0
  source = "./modules/aws/ssm/ec2/vulnerable/docker-log4shellapp"
  environment = var.infrastructure.config.context.global.environment
  deployment  = var.infrastructure.config.context.global.deployment
  listen_port = var.config.context.aws.ssm.vulnerable.docker.log4shellapp.listen_port
}

#########################
# Kubernetes General
#########################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.kubernetes.app.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/app"
  environment = var.infrastructure.config.context.global.environment
  deployment  = var.infrastructure.config.context.global.deployment
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.kubernetes.psp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/psp"
  environment = var.infrastructure.config.context.global.environment
  deployment  = var.infrastructure.config.context.global.deployment
}

#########################
# Kubernetes Vulnerable
#########################

module "vulnerable-kubernetes-voteapp" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/voteapp"
  environment         = var.infrastructure.config.context.global.environment
  deployment          = var.infrastructure.config.context.global.deployment
  region              = var.infrastructure.config.context.aws.region
  cluster_vpc_id      = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
  secret_credentials  = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

  vote_service_port   = var.config.context.kubernetes.vulnerable.voteapp.vote_service_port
  result_service_port = var.config.context.kubernetes.vulnerable.voteapp.result_service_port
  trusted_attacker_source   = var.config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
      local.attacker_eks_trusted_ips,
      local.attacker_ec2_trusted_ips
    ]) : []
  trusted_workstation_source = local.workstation_ips
  additional_trusted_sources = var.config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources
}

module "vulnerable-kubernetes-log4shellapp" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.log4shellapp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/log4shellapp"
  environment       = var.infrastructure.config.context.global.environment
  deployment        = var.infrastructure.config.context.global.deployment
  cluster_vpc_id    = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port      = var.config.context.kubernetes.vulnerable.log4shellapp.service_port
  trusted_attacker_source   = var.config.context.kubernetes.vulnerable.log4shellapp.trust_attacker_source ? flatten([
      local.attacker_eks_trusted_ips,
      local.attacker_ec2_trusted_ips
    ]) : []
  trusted_workstation_source = local.workstation_ips
  additional_trusted_sources = var.config.context.kubernetes.vulnerable.log4shellapp.additional_trusted_sources
}

module "vulnerable-kubernetes-rdsapp" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.rdsapp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/rdsapp"
  environment = var.infrastructure.config.context.global.environment
  deployment  = var.infrastructure.config.context.global.deployment
  region = var.infrastructure.config.context.aws.region
  cluster_vpc_id = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_sg_id
  cluster_vpc_subnet = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.url
  
  service_port     = var.config.context.kubernetes.vulnerable.rdsapp.service_port
  trusted_attacker_source   = var.config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
      local.attacker_eks_trusted_ips,
      local.attacker_ec2_trusted_ips
    ]) : []
  trusted_workstation_source = local.workstation_ips
  additional_trusted_sources = var.config.context.kubernetes.vulnerable.rdsapp.additional_trusted_sources
}

module "vulnerable-kubernetes-privileged-pod" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/privileged-pod"
  environment = var.infrastructure.config.context.global.environment
  deployment  = var.infrastructure.config.context.global.deployment
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/root-mount-fs-pod"
  environment = var.infrastructure.config.context.global.environment
  deployment  = var.infrastructure.config.context.global.deployment
}
