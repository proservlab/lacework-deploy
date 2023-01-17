# merge and validate configuration
locals {
  target_eks_public_ip = try(["${var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  attacker_eks_public_ip = try(["${var.infrastructure.deployed_state.attacker.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
}

#########################
# DEPLOYMENT CONTEXT
#########################

# get current context security group
data "aws_security_groups" "public" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
  tags = {
    environment = var.config.context.global.environment
    deployment  = var.config.context.global.deployment
    public = "true"
  }
}

data "aws_instances" "public_attacker" {
  provider = aws.attacker
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
  instance_tags = {
    environment = "attacker"
    deployment  = var.config.context.global.deployment
    public = "true"
  }
  instance_state_names = ["running"]
}

data "aws_instances" "public_target" {
  provider = aws.target
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
  instance_tags = {
    environment = "target"
    deployment  = var.config.context.global.deployment
    public = "true"
  }
  instance_state_names = ["running"]
}

#########################
# GENERAL
#########################

module "workstation-external-ip" {
  source       = "./modules/general/workstation-external-ip"
}

#########################
# AWS IAM
##########################

# create iam users
module "iam" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.iam.enabled == true ) ? 1 : 0
  source      = "./modules/aws/iam"
  environment       = var.config.context.global.environment
  deployment        = var.config.context.global.deployment
  region            = var.config.context.aws.region

  user_policies     = jsondecode(file(var.config.context.aws.iam.user_policies_path))
  users             = jsondecode(file(var.config.context.aws.iam.users_path))
}

#########################
# AWS EC2 SECURITY GROUP
##########################

# append ingress rules
module "ec2-add-trusted-ingress" {
  for_each = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? toset(data.aws_security_groups.public[0].ids) : toset([ for v in []: v ])
  source        = "./modules/aws/ec2/add-trusted-ingress"
  environment                   = var.config.context.global.environment
  deployment                    = var.config.context.global.deployment
  
  security_group_id             = each.key
  trusted_attacker_source       = var.config.context.aws.ec2.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source         = var.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for ip in data.aws_instances.public_target[0].public_ips: "${ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = var.config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = var.config.context.aws.ec2.add_trusted_ingress.trusted_tcp_ports
}

#########################
# AWS SSM
# ssm tag-based surface config
##########################

module "ssh-keys" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/aws/ssm/ec2/ssh-keys"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

module "vulnerable-docker-log4shellspp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.vulnerable.docker.log4shellapp.enabled == true ) ? 1 : 0
  source = "./modules/aws/ssm/ec2/vulnerable/docker-log4shellapp"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
  listen_port = var.config.context.aws.ssm.vulnerable.docker.log4shellapp.listen_port
}

#########################
# Kubernetes General
#########################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.app.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/app"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.psp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/psp"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

#########################
# Kubernetes Vulnerable
#########################

module "vulnerable-kubernetes-voteapp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/voteapp"
  environment                   = var.config.context.global.environment
  deployment                    = var.config.context.global.deployment
  region                        = var.config.context.aws.region
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
  secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

  vote_service_port             = var.config.context.kubernetes.vulnerable.voteapp.vote_service_port
  result_service_port           = var.config.context.kubernetes.vulnerable.voteapp.result_service_port
  trusted_attacker_source       = var.config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
    [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = var.config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources
}

module "vulnerable-kubernetes-log4shellapp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.log4shellapp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/log4shellapp"
  environment                   = var.config.context.global.environment
  deployment                    = var.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = var.config.context.kubernetes.vulnerable.log4shellapp.service_port
  trusted_attacker_source       = var.config.context.kubernetes.vulnerable.log4shellapp.trust_attacker_source ? flatten([
    [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = var.config.context.kubernetes.vulnerable.log4shellapp.additional_trusted_sources
}

module "vulnerable-kubernetes-rdsapp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.rdsapp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/rdsapp"
  environment                         = var.config.context.global.environment
  deployment                          = var.config.context.global.deployment
  region                              = var.config.context.aws.region
  cluster_vpc_id                      = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id                       = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_sg_id
  cluster_vpc_subnet                  = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.url
  
  service_port                        = var.config.context.kubernetes.vulnerable.rdsapp.service_port
  trusted_attacker_source             = var.config.context.kubernetes.vulnerable.rdsapp.trust_attacker_source ? flatten([
    [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source          = [module.workstation-external-ip.cidr]
  additional_trusted_sources          = var.config.context.kubernetes.vulnerable.rdsapp.additional_trusted_sources
}

module "vulnerable-kubernetes-privileged-pod" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/privileged-pod"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/root-mount-fs-pod"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}
