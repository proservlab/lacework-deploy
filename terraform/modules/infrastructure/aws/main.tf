##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../context/deployment"
}

##################################################
# LOCALS
##################################################

locals {
  config = var.config
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AWS EC2
##################################################

# ec2
module "ec2" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ec2.enabled == true && can(length(local.config.context.aws.ec2.instances))) ? 1 : 0
  source       = "./modules/ec2"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  # list of instances to configure
  instances = local.config.context.aws.ec2.instances

  # allow endpoints inside their own security group to communicate
  trust_security_group = local.config.context.global.trust_security_group

  public_ingress_rules = local.config.context.aws.ec2.public_ingress_rules
  public_egress_rules = local.config.context.aws.ec2.public_egress_rules
  public_app_ingress_rules = local.config.context.aws.ec2.public_app_ingress_rules
  public_app_egress_rules = local.config.context.aws.ec2.public_app_egress_rules
  private_ingress_rules = local.config.context.aws.ec2.private_ingress_rules
  private_egress_rules = local.config.context.aws.ec2.private_egress_rules
  private_app_ingress_rules = local.config.context.aws.ec2.private_app_ingress_rules
  private_app_egress_rules = local.config.context.aws.ec2.private_app_egress_rules

  public_network = local.config.context.aws.ec2.public_network
  public_subnet = local.config.context.aws.ec2.public_subnet
  public_app_network = local.config.context.aws.ec2.public_app_network
  public_app_subnet = local.config.context.aws.ec2.public_app_subnet
  private_network = local.config.context.aws.ec2.private_network
  private_subnet = local.config.context.aws.ec2.private_subnet
  private_nat_subnet = local.config.context.aws.ec2.private_nat_subnet
  private_app_network = local.config.context.aws.ec2.private_app_network
  private_app_subnet = local.config.context.aws.ec2.private_app_subnet
  private_app_nat_subnet = local.config.context.aws.ec2.private_app_nat_subnet
}

##################################################
# AWS EKS
##################################################

# eks
module "eks" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/eks"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.aws.region
  aws_profile_name = local.config.context.aws.profile_name

  cluster_name = local.config.context.aws.eks.cluster_name
}

# eks-autoscale
module "eks-autoscaler" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/eks-autoscale"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.aws.region
  
  cluster_name = local.config.context.aws.eks.cluster_name
  cluster_oidc_issuer = module.eks[0].cluster.identity[0].oidc[0].issuer
}

# eks
module "eks-windows" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks-windows.enabled == true ) ? 1 : 0
  source       = "./modules/eks-windows"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.aws.region
  aws_profile_name = local.config.context.aws.profile_name

  cluster_name = local.config.context.aws.eks.cluster_name
}

##################################################
# AWS INSPECTOR
##################################################

# inspector
module "inspector" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.inspector.enabled == true ) ? 1 : 0
  source       = "./modules/inspector"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

##################################################
# AWS SSM 
##################################################

# ssm deploy inspector agent
module "ssm-deploy-inspector-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_inspector_agent == true && local.config.context.aws.inspector.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-inspector-agent"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy git
module "ssm-deploy-git" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_git== true ) ? 1 : 0
  source       = "./modules/ssm/deploy-git"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy docker
module "ssm-deploy-docker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_docker== true ) ? 1 : 0
  source       = "./modules/ssm/deploy-docker"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy lacework agent
module "ssm-deploy-lacework-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_lacework_agent == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-agent"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  lacework_agent_access_token = local.config.context.lacework.agent.token
  lacework_server_url         = local.config.context.lacework.server_url
}

# ssm deploy lacework syscall_config.yaml
module "lacework-ssm-deployment-syscall-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_lacework_syscall_config == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-syscall-config"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  syscall_config = "${path.module}/modules/ssm/deploy-lacework-syscall-config/resources/syscall_config.yaml"
}

##################################################
# AWS RDS
##################################################

module "rds" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.rds.enabled == true ) ? 1 : 0
  source = "./modules/rds"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  
  igw_id                        = module.ec2[0].public_app_igw.id
  vpc_id                        = module.ec2[0].public_app_vpc.id
  vpc_subnet                    = module.ec2[0].public_app_network
  ec2_instance_role_name        = module.ec2[0].ec2_instance_app_role.name
  trusted_sg_id                 = module.ec2[0].public_app_sg.id
}