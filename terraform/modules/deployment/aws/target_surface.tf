locals {
  target_attacksurface_config = var.target_attacksurface_config

  target_eks_public_ip = try(["${local.target_infrastructure_deployed.aws.eks[0].cluster_nat_public_ip}/32"],[])
  
  target_public_sg = try(module.target-ec2[0].public_sg.id, null)
  target_public_app_sg = try(module.target-ec2[0].public_app_sg.id, null)

  target_db_host = try(module.target-rds[0].db_host, null)
  target_db_name = try(module.target-rds[0].db_name, null)
  target_db_user = try(module.target-rds[0].db_user, null)
  target_db_password = try(module.target-rds[0].db_password, null)
  target_db_port = try(module.target-rds[0].db_port, null)
  target_db_region = try(module.target-rds[0].db_region, null)

  # instances
  target_instances = try(module.target-ec2[0].instances, [])

  # public target instances
  public_target_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ]
  ])

  public_target_app_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  target_compromised_credentials = try(module.target-iam[0].access_keys, {})

  target_kubernetes_service_dns = { for service in flatten([
    try(module.target-kubernetes-app[0].services,[]),
    try(module.target-kubernetes-app-windows[0].services,[]),
    try(module.target-vulnerable-kubernetes-voteapp[0].services,[]),
    try(module.target-vulnerable-kubernetes-rdsapp[0].services,[]),
    try(module.target-vulnerable-kubernetes-log4j-app[0].services,[]),
    try(module.target-vulnerable-kubernetes-privileged-pod[0].services,[]),
    try(module.target-vulnerable-kubernetes-root-mount-fs-pod[0].services,[]),
    try(module.target-vulnerable-kubernetes-s3app[0].services,[]),
    try(module.target-vulnerable-kubernetes-authapp[0].services,[]),

  ]): service.name => service }
}

##################################################
# AWS IAM
##################################################

# create iam users
module "target-iam" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.iam.enabled == true ) ? 1 : 0
  source      = "./modules/iam"
  environment       = local.target_attacksurface_config.context.global.environment
  deployment        = local.target_attacksurface_config.context.global.deployment
  region            = local.target_infrastructure_config.context.aws.region

  user_policies     = jsondecode(templatefile(local.target_attacksurface_config.context.aws.iam.user_policies_path, { environment = local.target_attacksurface_config.context.global.environment, deployment = local.target_attacksurface_config.context.global.deployment }))
  users             = jsondecode(templatefile(local.target_attacksurface_config.context.aws.iam.users_path, { environment = local.target_attacksurface_config.context.global.environment, deployment = local.target_attacksurface_config.context.global.deployment }))
}

##################################################
# AWS EC2 SECURITY GROUP
##################################################

# append ingress rules
module "target-ec2-add-trusted-ingress" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/ec2-surface/add-trusted-ingress"
  environment                           = local.target_attacksurface_config.context.global.environment
  deployment                            = local.target_attacksurface_config.context.global.deployment
  
  security_group_id                     = local.default_public_sg
  trusted_attacker_source_enabled       = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_attacker_source
  trusted_attacker_source               = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source                 = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_workstation_source
  trusted_workstation_source            = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_workstation_source == true ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled    = length(local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources            = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports                     = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trusted_tcp_ports

  depends_on = [ 
    module.attacker-ec2,
    module.target-ec2,
    module.attacker-eks,
    module.targte-eks,
  ]
}

module "target-ec2-add-trusted-ingress-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/ec2-add-trusted-ingress"
  environment                           = local.target_attacksurface_config.context.global.environment
  deployment                            = local.target_attacksurface_config.context.global.deployment
  
  security_group_id                     = local.target_public_app_sg
  trusted_attacker_source_enabled       = local.target_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trust_attacker_source
  trusted_attacker_source               = local.target_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled         = local.target_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trust_target_source
  trusted_target_source                 = local.target_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_workstation_source
  trusted_workstation_source            = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_workstation_source == true ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled    = length(local.target_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources            = local.target_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports                     = local.target_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trusted_tcp_ports

  depends_on = [ 
    module.attacker-ec2,
    module.target-ec2,
    module.attacker-eks,
    module.targte-eks,
  ]
}

##################################################
# AWS SSM
##################################################

module "target-ssh-keys" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-ssh-keys"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment

  public_tag = "ssm_deploy_secret_ssh_public"
  private_tag = "ssm_deploy_secret_ssh_private"

  ssh_public_key_path = local.target_attacksurface_config.context.aws.ssm.ssh_keys.ssh_public_key_path
  ssh_private_key_path = local.target_attacksurface_config.context.aws.ssm.ssh_keys.ssh_private_key_path
  ssh_authorized_keys_path = local.target_attacksurface_config.context.aws.ssm.ssh_keys.ssh_authorized_keys_path
}

module "target-ssh-user" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ssm.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-ssh-user"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_ssh_user"

  username = local.target_attacksurface_config.context.aws.ssm.ssh_user.username
  password = local.target_attacksurface_config.context.aws.ssm.ssh_user.password
}

module "target-aws-credentials" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ssm.aws_credentials.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-aws-credentials"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment

  tag = "ssm_deploy_secret_aws_credentials"

  compromised_credentials = local.target_compromised_credentials
  compromised_keys_user = local.target_attacksurface_config.context.aws.ssm.aws_credentials.compromised_keys_user

  depends_on = [ 
    module.target-iam,
    module.attacker-iam
  ]
}

##################################################
# AWS SSM: Vulnerable Apps
##################################################

module "target-vulnerable-docker-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ssm.vulnerable.docker.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-docker-log4j-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_docker_log4j_app"

  listen_port = local.target_attacksurface_config.context.aws.ssm.vulnerable.docker.log4j_app.listen_port
}

module "target-vulnerable-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ssm.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-log4j-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_log4j_app"

  listen_port = local.target_attacksurface_config.context.aws.ssm.vulnerable.log4j_app.listen_port
}

module "target-vulnerable-npm-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ssm.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-npm-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_npm_app"

  listen_port = local.target_attacksurface_config.context.aws.ssm.vulnerable.npm_app.listen_port
}

module "target-vulnerable-python3-twisted-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ssm.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-python3-twisted-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_python3_twisted_app"

  listen_port = local.target_attacksurface_config.context.aws.ssm.vulnerable.python3_twisted_app.listen_port
}

module "target-vulnerable-rds-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.aws.ssm.vulnerable.rds_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-rds-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_rds_app"

  listen_port = local.target_attacksurface_config.context.aws.ssm.vulnerable.rds_app.listen_port

  db_host = local.target_db_host
  db_name = local.target_db_name
  db_user = local.target_db_user
  db_password = local.target_db_password
  db_port = local.target_db_port
  db_region = local.target_db_region

  depends_on = [
    module.target-rds
  ]
}


##################################################
# AWS EKS
##################################################

# assign iam user cluster readonly role
module "target-eks-auth" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.default_infrastructure_config.context.aws.eks.enabled == true && (local.target_attacksurface_config.context.aws.eks.add_iam_user_readonly_user.enabled == true || local.target_attacksurface_config.context.aws.eks.add_iam_user_admin_user.enabled == true || length([ for role in local.target_attacksurface_config.context.aws.eks.custom_cluster_roles: role.enabled if role.enabled == true ]) > 0 )) ? 1 : 0
  source      = "./modules/eks-auth"
  environment       = local.target_attacksurface_config.context.global.environment
  deployment        = local.target_attacksurface_config.context.global.deployment
  cluster_name      = local.target_cluster_name

  # user here needs to be created by iam module
  iam_eks_readers = local.target_attacksurface_config.context.aws.eks.add_iam_user_readonly_user.iam_user_names
  iam_eks_admins = local.target_attacksurface_config.context.aws.eks.add_iam_user_admin_user.iam_user_names
  custom_cluster_roles = local.target_attacksurface_config.context.aws.eks.custom_cluster_roles
  
  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]                  
}

##################################################
# Kubernetes General
##################################################

module "target-kubernetes-reloader" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.reloader.enabled == true ) ? 1 : 0
  source      = "../common/kubernetes-reloader"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}


# example of pushing kubernetes deployment via terraform
module "target-kubernetes-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.app.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-app"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  container_port                = 80 
  service_port                  = local.target_attacksurface_config.context.kubernetes.aws.app.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.app.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.aws.app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.target_attacksurface_config.context.kubernetes.aws.app.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.aws.app.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.target_attacksurface_config.context.kubernetes.aws.app.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.aws.app.additional_trusted_sources

  image                         = local.target_attacksurface_config.context.kubernetes.aws.app.image
  command                       = local.target_attacksurface_config.context.kubernetes.aws.app.command
  args                          = local.target_attacksurface_config.context.kubernetes.aws.app.args
  privileged                    = local.target_attacksurface_config.context.kubernetes.aws.app.privileged
  allow_privilege_escalation    = local.target_attacksurface_config.context.kubernetes.aws.app.allow_allow_privilege_escalation

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.app
  
  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}

module "target-kubernetes-app-windows" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.app-windows.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-app-windows"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = local.target_attacksurface_config.context.kubernetes.aws.app-windows.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.app-windows.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.aws.app-windows.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.app-windows.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.aws.app-windows.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.target_attacksurface_config.context.kubernetes.aws.app-windows.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.aws.app-windows.additional_trusted_sources

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.app-windows.enable_dynu_dns

  image                         = local.target_attacksurface_config.context.kubernetes.aws.app-windows.image
  command                       = local.target_attacksurface_config.context.kubernetes.aws.app-windows.command
  args                          = local.target_attacksurface_config.context.kubernetes.aws.app-windows.args
  privileged                    = local.target_attacksurface_config.context.kubernetes.aws.app-windows.privileged
  allow_privilege_escalation    = local.target_attacksurface_config.context.kubernetes.aws.app-windows.allow_allow_privilege_escalation
  
  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ] 
}

##################################################
# Kubernetes AWS Vulnerable
##################################################

module "target-vulnerable-kubernetes-voteapp" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.enabled == true) ? 1 : 0
  source                        = "./modules/kubernetes-voteapp"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  region                        = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
  secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

  vote_service_port             = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.vote_service_port
  result_service_port           = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.result_service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled  = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled    = length(local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.enable_dynu_dns

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }
  
  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}

module "target-vulnerable-kubernetes-rdsapp" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.enabled == true ) ? 1 : 0
  source                              = "./modules/kubernetes-rdsapp"
  environment                         = local.target_attacksurface_config.context.global.environment
  deployment                          = local.target_attacksurface_config.context.global.deployment
  region                              = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                      = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id                       = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_sg_id
  cluster_vpc_subnet                  = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.url
  
  service_port                        = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.service_port
  trusted_attacker_source_enabled     = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source
  trusted_attacker_source             = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled  = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_workstation_source
  trusted_workstation_source          = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources          = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.enable_dynu_dns

  privileged                    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.privileged
  allow_privilege_escalation    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.allow_allow_privilege_escalation

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}

module "target-vulnerable-kubernetes-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source                        = "./modules/kubernetes-log4j-app"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  container_port                = 8080 
  service_port                  = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.additional_trusted_sources

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.enable_dynu_dns

  image                         = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.image
  command                       = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.command
  args                          = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.args
  privileged                    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.privileged
  allow_privilege_escalation    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.allow_allow_privilege_escalation

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}

module "target-vulnerable-kubernetes-privileged-pod" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-privileged-pod"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.additional_trusted_sources
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.additional_trusted_sources

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.enable_dynu_dns

  image                         = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.image
  command                       = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.command
  args                          = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.args
  privileged                    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.privileged
  allow_privilege_escalation    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.allow_allow_privilege_escalation


  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}

module "target-vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-root-mount-fs-pod"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.additional_trusted_sources

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enable_dynu_dns

  image                         = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.image
  command                       = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.command
  args                          = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.args
  
  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}

module "target-vulnerable-kubernetes-s3app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.enabled == true ) ? 1 : 0
  source                              = "./modules/kubernetes-s3app"
  environment                         = local.target_attacksurface_config.context.global.environment
  deployment                          = local.target_attacksurface_config.context.global.deployment
  region                              = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                      = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id                       = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_sg_id
  cluster_vpc_subnet                  = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.url
  
  container_port                      = 80 
  service_port                        = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.service_port
  trusted_attacker_source_enabled     = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.trust_attacker_source
  trusted_attacker_source             = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled  = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.trust_workstation_source
  trusted_workstation_source          = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources          = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.additional_trusted_sources

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.enable_dynu_dns

  user_password = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.user_password
  admin_password = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.admin_password

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}

# example of pushing kubernetes deployment via terraform
module "target-vulnerable-kubernetes-authapp" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-authapp"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  container_port                = 80 
  service_port                  = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip,
  ])  : []
  trusted_target_source_enabled = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.additional_trusted_sources

  user_password = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.user_password
  admin_password = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.admin_password

  dynu_dns_domain_id = local.default_infrastructure_config.context.dynu_dns.domain_id
  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.enable_dynu_dns
  
  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-iam,
  ]
}
