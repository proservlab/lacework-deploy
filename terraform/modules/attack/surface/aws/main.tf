##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../context/deployment"
}

##################################################
# LOCALS
##################################################

locals {
  config = var.config
  
  default_infrastructure_config = var.infrastructure.config[var.config.context.global.environment]
  attacker_infrastructure_config = var.infrastructure.config["attacker"]
  target_infrastructure_config = var.infrastructure.config["target"]
  
  default_infrastructure_deployed = var.infrastructure.deployed_state[var.config.context.global.environment].context
  attacker_infrastructure_deployed = var.infrastructure.deployed_state["attacker"].context
  target_infrastructure_deployed = var.infrastructure.deployed_state["target"].context

  target_eks_public_ip = try(["${local.target_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  attacker_eks_public_ip = try(["${local.attacker_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

resource "time_sleep" "wait" {
  create_duration = "120s"
}

# get current context security group
data "aws_security_groups" "public" {
  count = (var.config.context.global.enable_all == true) || (
    var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
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

  depends_on = [time_sleep.wait]
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

  depends_on = [time_sleep.wait]
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AWS IAM
##################################################

# create iam users
module "iam" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.iam.enabled == true ) ? 1 : 0
  source      = "./modules/iam"
  environment       = var.config.context.global.environment
  deployment        = var.config.context.global.deployment
  region            = local.default_infrastructure_config.context.aws.region

  user_policies     = jsondecode(file(var.config.context.aws.iam.user_policies_path))
  users             = jsondecode(file(var.config.context.aws.iam.users_path))
}

##################################################
# AWS EC2 SECURITY GROUP
##################################################

# append ingress rules
module "ec2-add-trusted-ingress" {
  for_each = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? toset(data.aws_security_groups.public[0].ids) : toset([ for v in []: v ])
  source        = "./modules/ec2/add-trusted-ingress"
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

##################################################
# AWS EKS
##################################################

# assign iam user cluster readonly role
module "eks-auth" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.eks.add_iam_user_readonly_user.enabled == true ) ? 1 : 0
  source      = "./modules/eks/eks-auth"
  environment       = var.config.context.global.environment
  deployment        = var.config.context.global.deployment
  cluster_name      = local.default_infrastructure_config.context.aws.eks.cluster_name

  # user here needs to be created by iam module
  iam_eks_pod_readers = var.config.context.aws.eks.add_iam_user_readonly_user.iam_user_names

  depends_on = [
    module.iam
  ]                    
}

##################################################
# AWS SSM
# ssm tag-based surface config
##################################################

module "ssh-keys" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/ssh-keys"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

module "vulnerable-docker-log4shellapp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.vulnerable.docker.log4shellapp.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/vulnerable/docker-log4shellapp"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
  listen_port = var.config.context.aws.ssm.vulnerable.docker.log4shellapp.listen_port
}

module "vulnerable-npm-app" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/vulnerable/npm-app"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
  
  listen_port = var.config.context.aws.ssm.vulnerable.npm_app.listen_port
}

module "vulnerable-python3-twisted-app" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/vulnerable/python3-twisted-app"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
  
  listen_port = var.config.context.aws.ssm.vulnerable.python3_twisted_app.listen_port
}

##################################################
# Kubernetes General
##################################################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.aws.app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/app"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

module "kubernetes-app-windows" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.aws.app-windows.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/app-windows"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.aws.psp.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/psp"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

##################################################
# Kubernetes AWS Vulnerable
##################################################

module "vulnerable-kubernetes-voteapp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.aws.vulnerable.voteapp.enabled == true) ? 1 : 0
  source                        = "../kubernetes/aws/vulnerable/voteapp"
  environment                   = var.config.context.global.environment
  deployment                    = var.config.context.global.deployment
  region                        = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
  secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

  vote_service_port             = var.config.context.kubernetes.aws.vulnerable.voteapp.vote_service_port
  result_service_port           = var.config.context.kubernetes.aws.vulnerable.voteapp.result_service_port
  trusted_attacker_source       = var.config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source ? flatten([
    [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = var.config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources
}

module "vulnerable-kubernetes-rdsapp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.aws.vulnerable.rdsapp.enabled == true ) ? 1 : 0
  source                              = "../kubernetes/aws/vulnerable/rdsapp"
  environment                         = var.config.context.global.environment
  deployment                          = var.config.context.global.deployment
  region                              = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                      = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id                       = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_sg_id
  cluster_vpc_subnet                  = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.url
  
  service_port                        = var.config.context.kubernetes.aws.vulnerable.rdsapp.service_port
  trusted_attacker_source             = var.config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source ? flatten([
    [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source          = [module.workstation-external-ip.cidr]
  additional_trusted_sources          = var.config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources
}

module "vulnerable-kubernetes-log4shellapp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.aws.vulnerable.log4shellapp.enabled == true ) ? 1 : 0
  source                        = "../kubernetes/aws/vulnerable/log4shellapp"
  environment                   = var.config.context.global.environment
  deployment                    = var.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = var.config.context.kubernetes.aws.vulnerable.log4shellapp.service_port
  trusted_attacker_source       = var.config.context.kubernetes.aws.vulnerable.log4shellapp.trust_attacker_source ? flatten([
    [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = var.config.context.kubernetes.aws.vulnerable.log4shellapp.additional_trusted_sources
}

module "vulnerable-kubernetes-privileged-pod" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.aws.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/vulnerable/privileged-pod"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/vulnerable/root-mount-fs-pod"
  environment = var.config.context.global.environment
  deployment  = var.config.context.global.deployment
}
