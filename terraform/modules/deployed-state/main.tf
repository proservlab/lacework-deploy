locals {
    environment = local.config.context.global.environment
    deployment = var.config.context.global.deployment
    
    # aws enabled entities
    aws_ec2_enable = (var.config.context.global.enable_all == true || var.config.context.aws.ec2.enabled == true ) && var.config.context.global.disable_all == false && length(var.config.context.aws.ec2.instances) > 0 ? true : false
    aws_eks_enable = (var.config.context.global.enable_all == true || var.config.context.aws.eks.enabled == true ) && var.config.context.global.disable_all == false ? true : false
    aws_rds_enable = (var.config.context.global.enable_all == true || var.config.context.aws.rds.enabled == true ) && var.config.context.global.disable_all == false ? true : false
    
    # gcp
    # tbd

    # azure
    # tbd
}

module "workstation-external-ip" {
  source       = "./modules/general/workstation-external-ip"
}

module "aws-ec2" {
    count = local.aws_ec2_enable == true ? 1 : 0
    source = "./modules/aws/ec2"
    environment = local.environment
    deployment = local.deployment
}

module "aws-eks" {
    count = local.aws_eks_enable == true ? 1 : 0
    source = "./modules/aws/eks"
    environment = local.environment
    deployment = local.deployment
    region = var.config.context.aws.region
    aws_profile_name = var.config.context.aws.profile_name
    cluster_name = var.config.context.aws.eks.cluster_name
}

module "aws-rds" {
    count = local.aws_rds_enable == true ? 1 : 0
    source = "./modules/aws/rds"
    environment = local.environment
    deployment = local.deployment
}