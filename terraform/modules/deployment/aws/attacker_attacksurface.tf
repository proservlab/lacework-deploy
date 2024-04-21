
locals {
  attacker_attacksurface_config = var.attacker_attacksurface_config
  attacker_eks_public_ip = try(["${module.attacker-eks[0].cluster_nat_public_ip}/32"],[])
  attacker_public_sg = try(module.attacker-ec2[0].public_sg.id, null)
  attacker_public_app_sg = try(module.attacker-ec2[0].public_app_sg.id, null)
  attacker_private_nat_gw_ip = try(["${module.attacker-ec2[0].private_nat_gw.address}/32"], [])
  attacker_private_app_nat_gw_ip = try(["${module.attacker-ec2[0].private_app_nat_gw.address}/32"], [])
  attacker_db_host = try(module.attacker-rds[0].db_host, null)
  attacker_db_name = try(module.attacker-rds[0].db_name, null)
  attacker_db_user = try(module.attacker-rds[0].db_user, null)
  attacker_db_password = try(module.attacker-rds[0].db_password, null)
  attacker_db_port = try(module.attacker-rds[0].db_port, null)
  attacker_db_region = try(module.attacker-rds[0].db_region, null)
  attacker_instances = try(module.attacker-ec2[0].instances, [])

  # public attacker instances
  public_attacker_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ]
  ])

  public_attacker_app_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  attacker_compromised_credentials = try(module.attacker-iam[0].access_keys, {})

  attacker_kubernetes_service_dns = { for service in flatten([
    try(module.attacker-kubernetes-app[0].services,[]),
    try(module.attacker-kubernetes-app-windows[0].services,[]),
    try(module.attacker-vulnerable-kubernetes-voteapp[0].services,[]),
    try(module.attacker-vulnerable-kubernetes-rdsapp[0].services,[]),
    try(module.attacker-vulnerable-kubernetes-log4j-app[0].services,[]),
    try(module.attacker-vulnerable-kubernetes-privileged-pod[0].services,[]),
    try(module.attacker-vulnerable-kubernetes-root-mount-fs-pod[0].services,[]),
    try(module.attacker-vulnerable-kubernetes-s3app[0].services,[]),
    try(module.attacker-vulnerable-kubernetes-authapp[0].services,[]),

  ]): service.name => service }

  attacker_ssh_user = try(length(module.attacker-deploy-ssh-user[0]), "false") != "false" ? {
        username = module.attacker-deploy-ssh-user[0].username
        password = module.attacker-deploy-ssh-user[0].password
    } : null
}

##################################################
# AWS IAM
##################################################

# create iam users
module "attacker-iam" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.iam.enabled == true ) ? 1 : 0
  source      = "./modules/iam"
  environment       = local.attacker_attacksurface_config.context.global.environment
  deployment        = local.attacker_attacksurface_config.context.global.deployment
  region            = local.attacker_infrastructure_config.context.aws.region

  user_policies     = jsondecode(templatefile(local.attacker_attacksurface_config.context.aws.iam.user_policies_path, { environment = local.attacker_attacksurface_config.context.global.environment, deployment = local.attacker_attacksurface_config.context.global.deployment }))
  users             = jsondecode(templatefile(local.attacker_attacksurface_config.context.aws.iam.users_path, { environment = local.attacker_attacksurface_config.context.global.environment, deployment = local.attacker_attacksurface_config.context.global.deployment }))

  providers = {
    aws = aws.attacker
  }
}

##################################################
# AWS EC2 SECURITY GROUP
##################################################

# append ingress rules
module "attacker-ec2-add-trusted-ingress" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/ec2-add-trusted-ingress"
  environment                           = local.attacker_attacksurface_config.context.global.environment
  deployment                            = local.attacker_attacksurface_config.context.global.deployment
  
  security_group_id                     = local.attacker_public_sg
  trusted_attacker_source_enabled       = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_attacker_source
  trusted_attacker_source               = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip,
    local.attacker_private_nat_gw_ip
  ])  : []
  trusted_target_source_enabled         = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source                 = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip,
    local.target_private_nat_gw_ip
  ]) : []
  trusted_workstation_source_enabled    = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_workstation_source
  trusted_workstation_source            = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_workstation_source == true ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled    = length(local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources            = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports                     = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trusted_tcp_ports
  
  depends_on = [ 
    module.attacker-ec2,
    module.target-ec2,
    module.attacker-eks,
    module.target-eks,
  ]

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ec2-add-trusted-ingress-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/ec2-add-trusted-ingress"
  environment                           = local.attacker_attacksurface_config.context.global.environment
  deployment                            = local.attacker_attacksurface_config.context.global.deployment
  
  security_group_id                     = local.attacker_public_app_sg
  trusted_attacker_source_enabled       = local.attacker_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trust_attacker_source
  trusted_attacker_source               = local.attacker_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip,
    local.attacker_private_app_nat_gw_ip
  ])  : []
  trusted_target_source_enabled         = local.attacker_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trust_target_source
  trusted_target_source                 = local.attacker_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip,
    local.target_private_app_nat_gw_ip
  ]) : []
  trusted_workstation_source_enabled    = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_workstation_source
  trusted_workstation_source            = local.attacker_attacksurface_config.context.aws.ec2.add_trusted_ingress.trust_workstation_source == true ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources            = local.attacker_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports                     = local.attacker_attacksurface_config.context.aws.ec2.add_app_trusted_ingress.trusted_tcp_ports

  depends_on = [ 
    module.attacker-ec2,
    module.target-ec2,
    module.attacker-eks,
    module.target-eks,
  ]

  providers = {
    aws = aws.attacker
  }
}

##################################################
# AWS SSM
##################################################

module "attacker-ssh-keys" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-ssh-keys"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment

  public_tag = "ssm_deploy_secret_ssh_public"
  private_tag = "ssm_deploy_secret_ssh_private"

  ssh_public_key_path = local.attacker_attacksurface_config.context.aws.ssm.ssh_keys.ssh_public_key_path
  ssh_private_key_path = local.attacker_attacksurface_config.context.aws.ssm.ssh_keys.ssh_private_key_path
  ssh_authorized_keys_path = local.attacker_attacksurface_config.context.aws.ssm.ssh_keys.ssh_authorized_keys_path

  providers = {
    aws = aws.attacker
  }
}

module "attacker-deploy-ssh-user" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ssm.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-ssh-user"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_ssh_user"

  username = local.attacker_attacksurface_config.context.aws.ssm.ssh_user.username
  password = local.attacker_attacksurface_config.context.aws.ssm.ssh_user.password

  providers = {
    aws = aws.attacker
  }
}

module "attacker-aws-credentials" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ssm.aws_credentials.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-aws-credentials"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment

  tag = "ssm_deploy_secret_aws_credentials"

  compromised_credentials = local.target_compromised_credentials
  compromised_keys_user = local.attacker_attacksurface_config.context.aws.ssm.aws_credentials.compromised_keys_user

  depends_on = [ 
    module.target-iam,
    module.attacker-iam 
  ]

  providers = {
    aws = aws.attacker
  }
}

##################################################
# AWS SSM: Vulnerable Apps
##################################################

module "attacker-vulnerable-docker-log4j-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ssm.vulnerable.docker.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-docker-log4j-app"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_docker_log4j_app"

  listen_port = local.attacker_attacksurface_config.context.aws.ssm.vulnerable.docker.log4j_app.listen_port

  providers = {
    aws = aws.attacker
  }
}

module "attacker-vulnerable-log4j-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ssm.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-log4j-app"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_log4j_app"

  listen_port = local.attacker_attacksurface_config.context.aws.ssm.vulnerable.log4j_app.listen_port

  providers = {
    aws = aws.attacker
  }
}

module "attacker-vulnerable-npm-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ssm.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-npm-app"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_npm_app"

  listen_port = local.attacker_attacksurface_config.context.aws.ssm.vulnerable.npm_app.listen_port

  providers = {
    aws = aws.attacker
  }
}

module "attacker-vulnerable-python3-twisted-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ssm.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-python3-twisted-app"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_python3_twisted_app"

  listen_port = local.attacker_attacksurface_config.context.aws.ssm.vulnerable.python3_twisted_app.listen_port

  providers = {
    aws = aws.attacker
  }
}

module "attacker-vulnerable-rds-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.aws.ssm.vulnerable.rds_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-rds-app"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment
  
  tag = "ssm_deploy_rds_app"

  listen_port = local.attacker_attacksurface_config.context.aws.ssm.vulnerable.rds_app.listen_port

  db_host = local.attacker_db_host
  db_name = local.attacker_db_name
  db_user = local.attacker_db_user
  db_password = local.attacker_db_password
  db_port = local.attacker_db_port
  db_region = local.attacker_db_region

  depends_on = [
    module.attacker-rds
  ]

  providers = {
    aws = aws.attacker
  }
}


##################################################
# AWS EKS
##################################################

# assign iam user cluster readonly role
module "attacker-eks-auth" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks.enabled == true && (local.attacker_attacksurface_config.context.aws.eks.add_iam_user_readonly_user.enabled == true || local.attacker_attacksurface_config.context.aws.eks.add_iam_user_admin_user.enabled == true || length([ for role in local.attacker_attacksurface_config.context.aws.eks.custom_cluster_roles: role.enabled if role.enabled == true ]) > 0 )) ? 1 : 0
  source      = "./modules/eks-auth"
  environment       = local.attacker_attacksurface_config.context.global.environment
  deployment        = local.attacker_attacksurface_config.context.global.deployment
  cluster_name      = local.attacker_cluster_name

  # user here needs to be created by iam module
  iam_eks_readers = local.attacker_attacksurface_config.context.aws.eks.add_iam_user_readonly_user.iam_user_names
  iam_eks_admins = local.attacker_attacksurface_config.context.aws.eks.add_iam_user_admin_user.iam_user_names
  custom_cluster_roles = local.attacker_attacksurface_config.context.aws.eks.custom_cluster_roles

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ]

  providers = {
    aws         = aws.attacker
    kubernetes  = kubernetes.attacker
    helm        = helm.attacker
  }                  
}

##################################################
# Kubernetes General
##################################################

module "attacker-kubernetes-reloader" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.reloader.enabled == true ) ? 1 : 0
  source      = "../common/kubernetes-reloader"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
  }
}


# example of pushing kubernetes deployment via terraform
module "attacker-kubernetes-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.app.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-app"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment
  cluster_vpc_id                = module.attacker-eks[0].cluster_vpc_id

  container_port                = 80 
  service_port                  = local.attacker_attacksurface_config.context.kubernetes.aws.app.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.app.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.aws.app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.attacker_attacksurface_config.context.kubernetes.aws.app.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.aws.app.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.attacker_attacksurface_config.context.kubernetes.aws.app.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.aws.app.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.kubernetes.aws.app.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.aws.app.additional_trusted_sources

  image                         = local.attacker_attacksurface_config.context.kubernetes.aws.app.image
  command                       = local.attacker_attacksurface_config.context.kubernetes.aws.app.command
  args                          = local.attacker_attacksurface_config.context.kubernetes.aws.app.args
  privileged                    = local.attacker_attacksurface_config.context.kubernetes.aws.app.privileged
  allow_privilege_escalation    = local.attacker_attacksurface_config.context.kubernetes.aws.app.allow_allow_privilege_escalation

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.app

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}

module "attacker-kubernetes-app-windows" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-app-windows"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment
  cluster_vpc_id                = module.attacker-eks[0].cluster_vpc_id

  service_port                  = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.additional_trusted_sources

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.enable_dynu_dns

  image                         = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.image
  command                       = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.command
  args                          = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.args
  privileged                    = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.privileged
  allow_privilege_escalation    = local.attacker_attacksurface_config.context.kubernetes.aws.app-windows.allow_allow_privilege_escalation

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ] 

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}

##################################################
# Kubernetes AWS Vulnerable
##################################################

module "attacker-vulnerable-kubernetes-voteapp" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.enabled == true) ? 1 : 0
  source                        = "./modules/kubernetes-voteapp"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment
  region                        = local.attacker_infrastructure_config.context.aws.region
  cluster_vpc_id                = module.attacker-eks[0].cluster_vpc_id
  secret_credentials            = try(module.attacker-iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

  vote_service_port             = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.vote_service_port
  result_service_port           = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.result_service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled  = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled    = length(local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.voteapp.enable_dynu_dns

  depends_on = [
    module.attacker-eks,
    module.attacker-iam, 
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}

module "attacker-vulnerable-kubernetes-rdsapp" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.enabled == true ) ? 1 : 0
  source                              = "./modules/kubernetes-rdsapp"
  environment                         = local.attacker_attacksurface_config.context.global.environment
  deployment                          = local.attacker_attacksurface_config.context.global.deployment
  region                              = local.attacker_infrastructure_config.context.aws.region
  cluster_vpc_id                      = module.attacker-eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id                       = module.attacker-eks[0].cluster_sg_id
  cluster_vpc_subnet                  = module.attacker-eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = module.attacker-eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = module.attacker-eks[0].cluster_openid_connect_provider.url
  
  service_port                        = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.service_port
  trusted_attacker_source_enabled     = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source
  trusted_attacker_source             = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled  = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_workstation_source
  trusted_workstation_source          = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources          = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.enable_dynu_dns

  privileged                    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.privileged
  allow_privilege_escalation    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.rdsapp.allow_allow_privilege_escalation

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}

module "attacker-vulnerable-kubernetes-log4j-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source                        = "./modules/kubernetes-log4j-app"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment
  cluster_vpc_id                = module.attacker-eks[0].cluster_vpc_id

  container_port                = 8080 
  service_port                  = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.additional_trusted_sources

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.enable_dynu_dns

  image                         = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.image
  command                       = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.command
  args                          = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.args
  privileged                    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.privileged
  allow_privilege_escalation    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.log4j_app.allow_allow_privilege_escalation

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,    
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}

module "attacker-vulnerable-kubernetes-privileged-pod" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-privileged-pod"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment
  cluster_vpc_id                = module.attacker-eks[0].cluster_vpc_id

  service_port                  = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.additional_trusted_sources
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.additional_trusted_sources

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.enable_dynu_dns

  image                         = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.image
  command                       = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.command
  args                          = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.args
  privileged                    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.privileged
  allow_privilege_escalation    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.privileged_pod.allow_allow_privilege_escalation

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}

module "attacker-vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-root-mount-fs-pod"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment
  cluster_vpc_id                = module.attacker-eks[0].cluster_vpc_id

  service_port                  = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.additional_trusted_sources

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enable_dynu_dns

  image                         = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.image
  command                       = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.command
  args                          = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.args

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}

module "attacker-vulnerable-kubernetes-s3app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.enabled == true ) ? 1 : 0
  source                              = "./modules/kubernetes-s3app"
  environment                         = local.attacker_attacksurface_config.context.global.environment
  deployment                          = local.attacker_attacksurface_config.context.global.deployment
  region                              = local.attacker_infrastructure_config.context.aws.region
  cluster_vpc_id                      = module.attacker-eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id                       = module.attacker-eks[0].cluster_sg_id
  cluster_vpc_subnet                  = module.attacker-eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = module.attacker-eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = module.attacker-eks[0].cluster_openid_connect_provider.url
  
  container_port                      = 80 
  service_port                        = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.service_port
  trusted_attacker_source_enabled     = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.trust_attacker_source
  trusted_attacker_source             = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.attacker_attacksurface_config.context.vulnerable.s3app.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.vulnerable.s3app.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled  = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.trust_workstation_source
  trusted_workstation_source          = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources          = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.additional_trusted_sources

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.enable_dynu_dns

  user_password = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.user_password
  admin_password = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.s3app.admin_password

  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}

# example of pushing kubernetes deployment via terraform
module "attacker-vulnerable-kubernetes-authapp" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-authapp"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment
  cluster_vpc_id                = module.attacker-eks[0].cluster_vpc_id

  container_port                = 80 
  service_port                  = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip,
  ])  : []
  trusted_target_source_enabled = local.attacker_attacksurface_config.context.context.vulnerable.authapp.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.context.vulnerable.authapp.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.additional_trusted_sources

  user_password = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.user_password
  admin_password = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.admin_password

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.aws.vulnerable.authapp.enable_dynu_dns
  
  depends_on = [
    module.attacker-eks,
    module.attacker-iam,
  ]

  providers = {
    aws         = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    restapi  = restapi.main
  }
}