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
  region = var.infrastructure.config.context.aws.region
  user_policies = var.config.context.aws.iam.user_policies
  users = var.config.context.aws.iam.users
}

#########################
# AWS SSM
# ssm tag-based surface config
##########################

module "ssh-keys" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/aws/ssm/ec2/ssh-keys"
  environment = var.infrastructure.config.context.global.environment
}

module "log4j" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.aws.ssm.docker.log4j.enabled == true ) ? 1 : 0
  source = "./modules/aws/ssm/ec2/docker/log4j"
  environment = var.infrastructure.config.context.global.environment

}

#########################
# AWS RDS
##########################

module "rds" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.aws.rds.enabled == true ) ? 1 : 0
  source = "./modules/aws/rds"
  environment = var.infrastructure.config.context.global.environment
  
  igw_id                        = var.config.context.aws.rds.igw_id
  vpc_id                        = var.config.context.aws.rds.vpc_id
  vpc_subnet                    = var.config.context.aws.rds.vpc_subnet
  ec2_instance_role_name         = var.config.context.aws.rds.ec2_instance_role_name
  trusted_sg_id                 = var.config.context.aws.rds.trusted_sg_id
  root_db_username              = var.config.context.aws.rds.root_db_username
  root_db_password              = var.config.context.aws.rds.root_db_password
}

#########################
# Kubernetes General
#########################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.kubernetes.app.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/app"
  environment = var.infrastructure.config.context.global.environment
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.kubernetes.psp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/psp"
  environment = var.infrastructure.config.context.global.environment
}

#########################
# Kubernetes Vulnerable
#########################

module "vulnerable-kubernetes-voteapp" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/voteapp"
  environment = var.infrastructure.config.context.global.environment
  region      = var.infrastructure.config.context.aws.region
  cluster_vpc_id = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
  secret_credentials = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

  vote_service_port     = var.config.context.kubernetes.vulnerable.voteapp.vote_service_port
  result_service_port     = var.config.context.kubernetes.vulnerable.voteapp.result_service_port
  trusted_attacker_source   = var.config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
      local.attacker_eks_trusted_ips,
      local.attacker_ec2_trusted_ips
    ]) : []
  trusted_workstation_source    = local.workstation_ips
  additional_trusted_sources = var.config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources
}

module "vulnerable-kubernetes-log4shell" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.log4j.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/log4shell"
  environment = var.infrastructure.config.context.global.environment
  cluster_vpc_id = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port     = var.config.context.kubernetes.vulnerable.log4j.service_port
  trusted_attacker_source   = var.config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
      local.attacker_eks_trusted_ips,
      local.attacker_ec2_trusted_ips
    ]) : []
  trusted_workstation_source = local.workstation_ips
  additional_trusted_sources = var.config.context.kubernetes.vulnerable.log4j.additional_trusted_sources
}

module "vulnerable-kubernetes-rdsapp" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.rdsapp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/rdsapp"
  environment = var.infrastructure.config.context.global.environment
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
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/root-mount-fs-pod"
  environment = var.infrastructure.config.context.global.environment
}
