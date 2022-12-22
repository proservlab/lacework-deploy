# merge and validate configuration
locals {
  config = var.config
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
  source = "./modules/aws/ssm/ssh-keys"
  environment = var.infrastructure.config.context.global.environment
}

module "log4j" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.config.context.aws.ssm.docker.log4j.enabled == true ) ? 1 : 0
  source = "./modules/aws/ssm/docker/log4j"
  environment = var.infrastructure.config.context.global.environment
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
  cluster_vpc_id = var.infrastructure.deployed_state.context.aws.eks.cluster_vpc_id
  secret_credentials = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")
}

module "vulnerable-kubernetes-log4shell" {
  count = (var.infrastructure.config.context.global.enable_all == true) || (var.infrastructure.config.context.global.disable_all != true && var.infrastructure.config.context.aws.eks.enabled == true && var.config.context.kubernetes.vulnerable.log4j.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes/vulnerable/log4shell"
  environment = var.infrastructure.config.context.global.environment
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
