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

  target_eks_public_ip = try(["${local.target_infrastructure_deployed.aws.eks[0].cluster_nat_public_ip}/32"],[])
  attacker_eks_public_ip = try(["${local.attacker_infrastructure_deployed.aws.eks[0].cluster_nat_public_ip}/32"],[])
  
  default_public_sg = try(local.default_infrastructure_deployed.aws.ec2[0].public_sg.id, null)
  default_public_app_sg = try(local.default_infrastructure_deployed.aws.ec2[0].public_app_sg.id, null)
  target_public_sg = try(local.attacker_infrastructure_deployed.aws.ec2[0].public_sg.id, null)
  target_public_app_sg = try(local.attacker_infrastructure_deployed.aws.ec2[0].public_app_sg.id, null)
  attacker_public_sg = try(local.attacker_infrastructure_deployed.aws.ec2[0].public_sg.id, null)
  attacker_app_public_sg = try(local.attacker_infrastructure_deployed.aws.ec2[0].public_app_sg.id, null)

  cluster_name                        = try(local.default_infrastructure_deployed.aws.eks[0].cluster.id, "cluster")
  cluster_endpoint                    = try(local.default_infrastructure_deployed.aws.eks[0].cluster.endpoint, null)
  cluster_ca_cert                     = try(local.default_infrastructure_deployed.aws.eks[0].cluster.certificate_authority[0].data, null)
  cluster_oidc_issuer                 = try(local.default_infrastructure_deployed.aws.eks[0].cluster.identity[0].oidc[0].issuer, null)
  cluster_security_group              = try(local.default_infrastructure_deployed.aws.eks[0].cluster_sg_id, null)
  cluster_subnet                      = try(local.default_infrastructure_deployed.aws.eks[0].cluster_subnet, null)
  cluster_vpc_id                      = try(local.default_infrastructure_deployed.aws.eks[0].cluster_vpc_id, null)
  cluster_node_role_arn               = try(local.default_infrastructure_deployed.aws.eks[0].cluster_node_role_arn, null)
  cluster_vpc_subnet                  = try(local.default_infrastructure_deployed.aws.eks[0].cluster_vpc_subnet, null)
  cluster_openid_connect_provider_arn = try(local.default_infrastructure_deployed.aws.eks[0].cluster_openid_connect_provider.arn, null)
  cluster_openid_connect_provider_url = try(local.default_infrastructure_deployed.aws.eks[0].cluster_openid_connect_provider.url, null)

  db_host = try(local.default_infrastructure_deployed.aws.rds[0].db_host, null)
  db_name = try(local.default_infrastructure_deployed.aws.rds[0].db_name, null)
  db_user = try(local.default_infrastructure_deployed.aws.rds[0].db_user, null)
  db_password = try(local.default_infrastructure_deployed.aws.rds[0].db_password, null)
  db_port = try(local.default_infrastructure_deployed.aws.rds[0].db_port, null)
  db_region = try(local.default_infrastructure_deployed.aws.rds[0].db_region, null)

  aws_profile_name = local.default_infrastructure_config.context.aws.profile_name
  aws_region = local.default_infrastructure_config.context.aws.region

  # instances
  default_instances = try(local.default_infrastructure_deployed.aws.ec2[0].instances, [])
  attacker_instances = try(local.attacker_infrastructure_deployed.aws.ec2[0].instances, [])
  target_instances = try(local.target_infrastructure_deployed.aws.ec2[0].instances, [])

  # public targets
  public_attacker_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ]
  ])

  public_attacker_app_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])

  public_target_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.tags.role == "default" && compute.instance.tags.public == "true" ]
  ])

  public_target_app_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.tags.role == "app" && compute.instance.tags.public == "true" ]
  ])
}



##################################################
# DEPLOYMENT CONTEXT
##################################################

# resource "time_sleep" "wait" {
#   create_duration = "120s"
# }

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
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.iam.enabled == true ) ? 1 : 0
  source      = "./modules/iam"
  environment       = local.config.context.global.environment
  deployment        = local.config.context.global.deployment
  region            = local.default_infrastructure_config.context.aws.region

  user_policies     = jsondecode(templatefile(local.config.context.aws.iam.user_policies_path, { environment = local.config.context.global.environment, deployment = local.config.context.global.deployment }))
  users             = jsondecode(templatefile(local.config.context.aws.iam.users_path, { environment = local.config.context.global.environment, deployment = local.config.context.global.deployment }))
}

##################################################
# AWS EC2 SECURITY GROUP
##################################################

# append ingress rules
module "ec2-add-trusted-ingress" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/ec2/add-trusted-ingress"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  
  security_group_id             = local.default_public_sg
  trusted_attacker_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_attacker_source
  trusted_attacker_source       = local.config.context.aws.ec2.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_workstation_source
  trusted_workstation_source    = local.config.context.aws.ec2.add_trusted_ingress.trust_workstation_source == true ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.config.context.aws.ec2.add_trusted_ingress.trusted_tcp_ports
}

module "ec2-add-trusted-ingress-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ec2.add_app_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/ec2/add-trusted-ingress"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  
  security_group_id             = local.default_public_app_sg
  trusted_attacker_source_enabled       = local.config.context.aws.ec2.add_app_trusted_ingress.trust_attacker_source
  trusted_attacker_source       = local.config.context.aws.ec2.add_app_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_app_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_workstation_source
  trusted_workstation_source    = local.config.context.aws.ec2.add_trusted_ingress.trust_workstation_source == true ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.config.context.aws.ec2.add_app_trusted_ingress.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.config.context.aws.ec2.add_app_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.config.context.aws.ec2.add_app_trusted_ingress.trusted_tcp_ports
}

##################################################
# AWS SSM
##################################################

module "ssh-keys" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-ssh-keys"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  public_tag = "ssm_deploy_secret_ssh_public"
  private_tag = "ssm_deploy_secret_ssh_private"

  ssh_public_key_path = local.config.context.aws.ssm.ssh_keys.ssh_public_key_path
  ssh_private_key_path = local.config.context.aws.ssm.ssh_keys.ssh_private_key_path
  ssh_authorized_keys_path = local.config.context.aws.ssm.ssh_keys.ssh_authorized_keys_path
}

module "ssh-user" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-ssh-user"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  tag = "ssm_deploy_ssh_user"

  username = local.config.context.aws.ssm.ssh_user.username
  password = local.config.context.aws.ssm.ssh_user.password
}

module "aws-credentials" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.aws_credentials.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-aws-credentials"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  tag = "ssm_deploy_secret_aws_credentials"

  compromised_credentials = var.compromised_credentials
  compromised_keys_user = local.config.context.aws.ssm.aws_credentials.compromised_keys_user

  depends_on = [ module.iam ]
}

##################################################
# AWS SSM: Vulnerable Apps
##################################################

module "vulnerable-docker-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.docker.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-docker-log4j-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  tag = "ssm_deploy_docker_log4j_app"

  listen_port = local.config.context.aws.ssm.vulnerable.docker.log4j_app.listen_port
}

module "vulnerable-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-log4j-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  tag = "ssm_deploy_log4j_app"

  listen_port = local.config.context.aws.ssm.vulnerable.log4j_app.listen_port
}

module "vulnerable-npm-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-npm-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  tag = "ssm_deploy_npm_app"

  listen_port = local.config.context.aws.ssm.vulnerable.npm_app.listen_port
}

module "vulnerable-python3-twisted-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-python3-twisted-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  tag = "ssm_deploy_python3_twisted_app"

  listen_port = local.config.context.aws.ssm.vulnerable.python3_twisted_app.listen_port
}

module "vulnerable-rds-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.rds_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/deploy-rds-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  tag = "ssm_deploy_rds_app"

  listen_port = local.config.context.aws.ssm.vulnerable.rds_app.listen_port

  db_host = local.db_host
  db_name = local.db_name
  db_user = local.db_user
  db_password = local.db_password
  db_port = local.db_port
  db_region = local.db_region
}


##################################################
# AWS EKS
##################################################

# module "eks-kubeconfig" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.default_infrastructure_config.context.aws.eks.enabled == true) ? 1 : 0
#   source = "./modules/eks/eks-kubeconfig"

#   environment = local.config.context.global.environment
#   deployment = local.config.context.global.deployment
#   aws_profile_name = local.aws_profile_name
#   region = local.aws_region
#   cluster_name = local.cluster_name
#   kubeconfig_path = local.default_kubeconfig
# }

# resource "time_sleep" "wait_2_minutes" {
#   create_duration = "120s"
#   depends_on = [# module.eks-kubeconfig]
# }

# assign iam user cluster readonly role
module "eks-auth" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.default_infrastructure_config.context.aws.eks.enabled == true && (local.config.context.aws.eks.add_iam_user_readonly_user.enabled == true || local.config.context.aws.eks.add_iam_user_admin_user.enabled == true || length([ for role in local.config.context.aws.eks.custom_cluster_roles: role.enabled if role.enabled == true ]) > 0 )) ? 1 : 0
  source      = "./modules/eks/eks-auth"
  environment       = local.config.context.global.environment
  deployment        = local.config.context.global.deployment
  cluster_name      = local.cluster_name

  # user here needs to be created by iam module
  iam_eks_readers = local.config.context.aws.eks.add_iam_user_readonly_user.iam_user_names
  iam_eks_admins = local.config.context.aws.eks.add_iam_user_admin_user.iam_user_names
  custom_cluster_roles = local.config.context.aws.eks.custom_cluster_roles
  
  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    # time_sleep.wait_2_minutes,
    module.iam,
    # module.eks-kubeconfig
  ]                    
}

##################################################
# Kubernetes General
##################################################
module "kubernetes-reloader" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.reloader.enabled == true ) ? 1 : 0
  source      = "../kubernetes/common/reloader"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}


# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/app"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  container_port                = 80 
  service_port                  = local.config.context.kubernetes.aws.app.service_port
  trusted_attacker_source_enabled = local.config.context.kubernetes.aws.app.trust_attacker_source
  trusted_attacker_source       = local.config.context.kubernetes.aws.app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.config.context.kubernetes.aws.app.trust_workstation_source
  trusted_workstation_source    = local.config.context.kubernetes.aws.app.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.config.context.kubernetes.aws.app.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.config.context.kubernetes.aws.app.additional_trusted_sources

  image                         = local.config.context.kubernetes.aws.app.image
  command                       = local.config.context.kubernetes.aws.app.command
  args                          = local.config.context.kubernetes.aws.app.args

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.app
  
  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

module "kubernetes-app-windows" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.app-windows.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/app-windows"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = local.config.context.kubernetes.aws.app-windows.service_port
  trusted_attacker_source_enabled = local.config.context.kubernetes.aws.app-windows.trust_attacker_source
  trusted_attacker_source       = local.config.context.kubernetes.aws.app-windows.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.config.context.kubernetes.aws.app-windows.trust_workstation_source
  trusted_workstation_source    = local.config.context.kubernetes.aws.app-windows.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.config.context.kubernetes.aws.app-windows.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.config.context.kubernetes.aws.app-windows.additional_trusted_sources

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.app-windows.enable_dynu_dns

  image                         = local.config.context.kubernetes.aws.app-windows.image
  command                       = local.config.context.kubernetes.aws-windows.app.command
  args                          = local.config.context.kubernetes.aws.app-windows.args
  
  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

##################################################
# Kubernetes AWS Vulnerable
##################################################

module "vulnerable-kubernetes-voteapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.voteapp.enabled == true) ? 1 : 0
  source                        = "../kubernetes/aws/voteapp"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  region                        = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
  secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

  vote_service_port             = local.config.context.kubernetes.aws.vulnerable.voteapp.vote_service_port
  result_service_port           = local.config.context.kubernetes.aws.vulnerable.voteapp.result_service_port
  trusted_attacker_source_enabled = local.config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source
  trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled  = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.config.context.kubernetes.aws.vulnerable.voteapp.trust_workstation_source
  trusted_workstation_source    = local.config.context.kubernetes.aws.vulnerable.voteapp.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled    = length(local.config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.vulnerable.voteapp.enable_dynu_dns

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
  
  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

module "vulnerable-kubernetes-rdsapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.rdsapp.enabled == true ) ? 1 : 0
  source                              = "../kubernetes/aws/rdsapp"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  region                              = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                      = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id                       = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_sg_id
  cluster_vpc_subnet                  = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.url
  
  service_port                        = local.config.context.kubernetes.aws.vulnerable.rdsapp.service_port
  trusted_attacker_source_enabled     = local.config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source
  trusted_attacker_source             = local.config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled  = local.config.context.kubernetes.aws.vulnerable.rdsapp.trust_workstation_source
  trusted_workstation_source          = local.config.context.kubernetes.aws.vulnerable.rdsapp.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources          = local.config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.vulnerable.rdsapp.enable_dynu_dns

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

module "vulnerable-kubernetes-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source                        = "../kubernetes/aws/log4j-app"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  container_port                = 8080 
  service_port                  = local.config.context.kubernetes.aws.vulnerable.log4j_app.service_port
  trusted_attacker_source_enabled = local.config.context.kubernetes.aws.vulnerable.log4j_app.trust_attacker_source
  trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.log4j_app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.config.context.kubernetes.aws.vulnerable.log4j_app.trust_workstation_source
  trusted_workstation_source    = local.config.context.kubernetes.aws.vulnerable.log4j_app.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.config.context.kubernetes.aws.vulnerable.log4j_app.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.log4j_app.additional_trusted_sources

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.vulnerable.log4j_app.enable_dynu_dns

  image                         = local.config.context.kubernetes.aws.vulnerable.log4j_app.image
  command                       = local.config.context.kubernetes.aws.vulnerable.log4j_app.command
  args                          = local.config.context.kubernetes.aws.vulnerable.log4j_app.args

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

module "vulnerable-kubernetes-privileged-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/privileged-pod"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = local.config.context.kubernetes.aws.vulnerable.privileged_pod.service_port
  trusted_attacker_source_enabled = local.config.context.kubernetes.aws.vulnerable.privileged_pod.trust_attacker_source
  trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.privileged_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.config.context.kubernetes.aws.vulnerable.privileged_pod.trust_workstation_source
  trusted_workstation_source    = local.config.context.kubernetes.aws.vulnerable.privileged_pod.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = local.config.context.kubernetes.aws.vulnerable.privileged_pod.additional_trusted_sources
  additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.privileged_pod.additional_trusted_sources

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.vulnerable.privileged_pod.enable_dynu_dns

  image                         = local.config.context.kubernetes.aws.vulnerable.privileged_pod.image
  command                       = local.config.context.kubernetes.aws.vulnerable.privileged_pod.command
  args                          = local.config.context.kubernetes.aws.vulnerable.privileged_pod.args

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/root-mount-fs-pod"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.service_port
  trusted_attacker_source_enabled = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_attacker_source
  trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_workstation_source
  trusted_workstation_source    = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.additional_trusted_sources

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enable_dynu_dns

  image                         = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.image
  command                       = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.command
  args                          = local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.args
  
  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

module "vulnerable-kubernetes-s3app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.s3app.enabled == true ) ? 1 : 0
  source                              = "../kubernetes/aws/s3app"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  region                              = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                      = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  # trusted security group for rds connections
  cluster_sg_id                       = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_sg_id
  cluster_vpc_subnet                  = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_subnet
  
  # oidc provider for pod assumed database roles
  cluster_openid_connect_provider_arn = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.arn
  cluster_openid_connect_provider_url = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_openid_connect_provider.url
  
  container_port                      = 80 
  service_port                        = local.config.context.kubernetes.aws.vulnerable.s3app.service_port
  trusted_attacker_source_enabled     = local.config.context.kubernetes.aws.vulnerable.s3app.trust_attacker_source
  trusted_attacker_source             = local.config.context.kubernetes.aws.vulnerable.s3app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled  = local.config.context.kubernetes.aws.vulnerable.s3app.trust_workstation_source
  trusted_workstation_source          = local.config.context.kubernetes.aws.vulnerable.s3app.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled  = length(local.config.context.kubernetes.aws.vulnerable.s3app.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources          = local.config.context.kubernetes.aws.vulnerable.s3app.additional_trusted_sources

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.vulnerable.s3app.enable_dynu_dns

  user_password = local.config.context.kubernetes.aws.vulnerable.s3app.user_password
  admin_password = local.config.context.kubernetes.aws.vulnerable.s3app.admin_password

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

# example of pushing kubernetes deployment via terraform
module "kubernetes-authapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.authapp.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/authapp"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  container_port                = 80 
  service_port                  = local.config.context.kubernetes.aws.vulnerable.authapp.service_port
  trusted_attacker_source_enabled = local.config.context.kubernetes.aws.vulnerable.authapp.trust_attacker_source
  trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.authapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip,
  ])  : []
  trusted_target_source_enabled = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.config.context.kubernetes.aws.vulnerable.authapp.trust_workstation_source
  trusted_workstation_source    = local.config.context.kubernetes.aws.vulnerable.authapp.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.config.context.kubernetes.aws.vulnerable.authapp.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.authapp.additional_trusted_sources

  user_password = local.config.context.kubernetes.aws.vulnerable.authapp.user_password
  admin_password = local.config.context.kubernetes.aws.vulnerable.authapp.admin_password

  dynu_dns_domain = local.default_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.config.context.kubernetes.aws.vulnerable.authapp.enable_dynu_dns
  
  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [ 
    module.eks-auth,
    # module.eks-kubeconfig
  ]
}

locals {
  service_dns = { for service in flatten([
    try(module.kubernetes-app[0].services,[]),
    try(module.kubernetes-app-windows[0].services,[]),
    try(module.vulnerable-kubernetes-voteapp[0].services,[]),
    try(module.vulnerable-kubernetes-rdsapp[0].services,[]),
    try(module.vulnerable-kubernetes-log4j-app[0].services,[]),
    try(module.vulnerable-kubernetes-privileged-pod[0].services,[]),
    try(module.vulnerable-kubernetes-root-mount-fs-pod[0].services,[]),
    try(module.vulnerable-kubernetes-s3app[0].services,[]),

  ]): service.name => service }
}
