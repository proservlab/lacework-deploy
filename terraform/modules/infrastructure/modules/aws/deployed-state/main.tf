locals {
    environment = var.config.context.global.environment
    deployment = var.config.context.global.deployment
    aws_ec2_enable = (var.config.context.global.enable_all == true || var.config.context.aws.ec2.enabled == true ) && var.context.global.disable_all == false && length(var.config.context.aws.ec2.instances) > 0 ? true : false
    aws_eks_enable = (var.config.context.global.enable_all == true || var.config.context.aws.eks.enabled == true ) && var.context.global.disable_all == false ? true : false
}

module "aws-ec2" {
    count = local.aws_ec2_enable == true ? 1 : 0
    environment = local.environment
    deployment = local.deployment
}

module "aws-eks" {
    count = local.aws_eks_enable == true ? 1 : 0
    environment = local.environment
    deployment = local.deployment
    cluster_name = var.config.context.aws.eks.cluster_name
}

module "aws-eks" {
    count = local.aws_rds_enable == true ? 1 : 0
    environment = local.environment
    deployment = local.deployment
}