##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../context/deployment"
}

##################################################
# LOCALS
##################################################

module "default-config" {
  source = "../../../context/attack/surface"
}

locals {
  config = try(length(var.config), {}) == {} ? module.default-config.config : var.config
  
  default_infrastructure_config = var.infrastructure.config[local.config.context.global.environment]
  attacker_infrastructure_config = var.infrastructure.config["attacker"]
  target_infrastructure_config = var.infrastructure.config["target"]
  
  default_infrastructure_deployed = var.infrastructure.deployed_state[local.config.context.global.environment].context
  attacker_infrastructure_deployed = var.infrastructure.deployed_state["attacker"].context
  target_infrastructure_deployed = var.infrastructure.deployed_state["target"].context

  resource_group = try(local.default_infrastructure_deployed.azure.compute[0].resource_group, null)
  public_security_group = try(local.default_infrastructure_deployed.azure.compute[0].public_security_group, null)

  # target_eks_public_ip = try(["${local.target_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  # attacker_eks_public_ip = try(["${local.attacker_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

resource "time_sleep" "wait" {
  create_duration = "120s"
}

# need security group and resource group
resource "azurerm_network_security_rule" "example" {
  count = try(local.default_infrastructure_deployed.azure.compute[0], "false") != "false" ? 1 : 0
  name                        = "test123"
  priority                    = 100
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group.name
  network_security_group_name = local.public_security_group.name

  depends_on = [
    time_sleep.wait
  ]
}

# data "azurerm_public_ips" "example" {
#   resource_group_name = "pip-test"
#   attachment_status   = "Attached"
# }

# # get current context security group
# data "aws_security_groups" "public" {
#   count = (local.config.context.global.enable_all == true) || (
#     local.config.context.global.disable_all != true && local.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
#   tags = {
#     environment = local.config.context.global.environment
#     deployment  = local.config.context.global.deployment
#     public = "true"
#   }
# }

# data "aws_instances" "public_attacker" {
#   provider = aws.attacker
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
#   instance_tags = {
#     environment = "attacker"
#     deployment  = local.config.context.global.deployment
#     public = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# data "aws_instances" "public_target" {
#   provider = aws.target
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
#   instance_tags = {
#     environment = "target"
#     deployment  = local.config.context.global.deployment
#     public = "true"
#   }

#   instance_state_names = ["running"]

#   depends_on = [time_sleep.wait]
# }

# ##################################################
# # GENERAL
# ##################################################

# module "workstation-external-ip" {
#   source       = "../general/workstation-external-ip"
# }

# ##################################################
# # AWS IAM
# ##################################################

# # create iam users
# module "iam" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.iam.enabled == true ) ? 1 : 0
#   source      = "./modules/iam"
#   environment       = local.config.context.global.environment
#   deployment        = local.config.context.global.deployment
#   region            = local.default_infrastructure_config.context.aws.region

#   user_policies     = jsondecode(file(local.config.context.aws.iam.user_policies_path))
#   users             = jsondecode(file(local.config.context.aws.iam.users_path))
# }

# ##################################################
# # AWS EC2 SECURITY GROUP
# ##################################################

# # append ingress rules
# module "ec2-add-trusted-ingress" {
#   for_each = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? toset(data.aws_security_groups.public[0].ids) : toset([ for v in []: v ])
#   source        = "./modules/ec2/add-trusted-ingress"
#   environment                   = local.config.context.global.environment
#   deployment                    = local.config.context.global.deployment
  
#   security_group_id             = each.key
#   trusted_attacker_source       = local.config.context.aws.ec2.add_trusted_ingress.trust_attacker_source ? flatten([
#     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_eks_public_ip
#   ])  : []
#   trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
#     [ for ip in data.aws_instances.public_target[0].public_ips: "${ip}/32" ],
#     local.target_eks_public_ip
#   ]) : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources
#   trusted_tcp_ports             = local.config.context.aws.ec2.add_trusted_ingress.trusted_tcp_ports
# }

# ##################################################
# # AWS EKS
# ##################################################

# # assign iam user cluster readonly role
# module "eks-auth" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.add_iam_user_readonly_user.enabled == true ) ? 1 : 0
#   source      = "./modules/eks/eks-auth"
#   environment       = local.config.context.global.environment
#   deployment        = local.config.context.global.deployment
#   cluster_name      = local.default_infrastructure_config.context.aws.eks.cluster_name

#   # user here needs to be created by iam module
#   iam_eks_pod_readers = local.config.context.aws.eks.add_iam_user_readonly_user.iam_user_names

#   depends_on = [
#     module.iam
#   ]                    
# }

# ##################################################
# # AWS SSM
# # ssm tag-based surface config
# ##################################################

# module "ssh-keys" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
#   source = "./modules/ssm/ec2/ssh-keys"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
# }

# module "vulnerable-docker-log4shellapp" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.docker.log4shellapp.enabled == true ) ? 1 : 0
#   source = "./modules/ssm/ec2/vulnerable/docker-log4shellapp"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
#   listen_port = local.config.context.aws.ssm.vulnerable.docker.log4shellapp.listen_port
# }

# module "vulnerable-npm-app" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.npm_app.enabled == true ) ? 1 : 0
#   source = "./modules/ssm/ec2/vulnerable/npm-app"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
  
#   listen_port = local.config.context.aws.ssm.vulnerable.npm_app.listen_port
# }

# module "vulnerable-python3-twisted-app" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
#   source = "./modules/ssm/ec2/vulnerable/python3-twisted-app"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
  
#   listen_port = local.config.context.aws.ssm.vulnerable.python3_twisted_app.listen_port
# }

# ##################################################
# # Kubernetes General
# ##################################################

# # example of pushing kubernetes deployment via terraform
# module "kubernetes-app" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.app.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/aws/app"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
# }

# module "kubernetes-app-windows" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.app-windows.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/aws/app-windows"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
# }

# # example of applying pod security policy
# module "kubenetes-psp" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.psp.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/aws/psp"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
# }

# ##################################################
# # Kubernetes AWS Vulnerable
# ##################################################

# module "vulnerable-kubernetes-voteapp" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.voteapp.enabled == true) ? 1 : 0
#   source                        = "../kubernetes/aws/vulnerable/voteapp"
#   environment                   = local.config.context.global.environment
#   deployment                    = local.config.context.global.deployment
#   region                        = local.default_infrastructure_config.context.aws.region
#   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
#   secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

#   vote_service_port             = local.config.context.kubernetes.aws.vulnerable.voteapp.vote_service_port
#   result_service_port           = local.config.context.kubernetes.aws.vulnerable.voteapp.result_service_port
#   trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source ? flatten([
#     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_eks_public_ip
#   ])  : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources
# }

# module "vulnerable-kubernetes-rdsapp" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.rdsapp.enabled == true ) ? 1 : 0
#   source                              = "../kubernetes/aws/vulnerable/rdsapp"
#   environment                         = local.config.context.global.environment
#   deployment                          = local.config.context.global.deployment
#   region                              = local.default_infrastructure_config.context.aws.region
#   cluster_vpc_id                      = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

#   # trusted security group for rds connections
#   cluster_sg_id                       = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_sg_id
#   cluster_vpc_subnet                  = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_subnet
  
#   # oidc provider for pod assumed database roles
#   cluster_openid_connect_provider_arn = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.arn
#   cluster_openid_connect_provider_url = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.url
  
#   service_port                        = local.config.context.kubernetes.aws.vulnerable.rdsapp.service_port
#   trusted_attacker_source             = local.config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source ? flatten([
#     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_eks_public_ip
#   ])  : []
#   trusted_workstation_source          = [module.workstation-external-ip.cidr]
#   additional_trusted_sources          = local.config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources
# }

# module "vulnerable-kubernetes-log4shellapp" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.log4shellapp.enabled == true ) ? 1 : 0
#   source                        = "../kubernetes/aws/vulnerable/log4shellapp"
#   environment                   = local.config.context.global.environment
#   deployment                    = local.config.context.global.deployment
#   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

#   service_port                  = local.config.context.kubernetes.aws.vulnerable.log4shellapp.service_port
#   trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.log4shellapp.trust_attacker_source ? flatten([
#     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_eks_public_ip
#   ])  : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.log4shellapp.additional_trusted_sources
# }

# module "vulnerable-kubernetes-privileged-pod" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/aws/vulnerable/privileged-pod"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
# }

# module "vulnerable-kubernetes-root-mount-fs-pod" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/aws/vulnerable/root-mount-fs-pod"
#   environment = local.config.context.global.environment
#   deployment  = local.config.context.global.deployment
# }
