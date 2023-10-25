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

  target_eks_public_ip = try(["${local.target_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  attacker_eks_public_ip = try(["${local.attacker_infrastructure_deployed.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  
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

  default_kubeconfig = try(local.default_infrastructure_deployed.aws.eks[0].kubeconfig, pathexpand("~/.kube/config"))
  target_kubeconfig = try(local.target_infrastructure_deployed.aws.eks[0].kubeconfig, pathexpand("~/.kube/config"))
  attacker_kubeconfig = try(local.attacker_infrastructure_deployed.aws.eks[0].kubeconfig, pathexpand("~/.kube/config"))

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

resource "null_resource" "log" {
  triggers = {
    log_message = jsonencode(local.config)
  }

  provisioner "local-exec" {
    command = "echo '${jsonencode(local.config)}'"
  }
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

resource "time_sleep" "wait" {
  create_duration = "120s"
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
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.iam.enabled == true ) ? 1 : 0
  source      = "./modules/iam"
  environment       = local.config.context.global.environment
  deployment        = local.config.context.global.deployment
  region            = local.default_infrastructure_config.context.aws.region

  user_policies     = jsondecode(file(local.config.context.aws.iam.user_policies_path))
  users             = jsondecode(file(local.config.context.aws.iam.users_path))
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
  trusted_attacker_source       = local.config.context.aws.ec2.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source         = local.config.context.aws.ec2.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.aws.ec2.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.config.context.aws.ec2.add_trusted_ingress.trusted_tcp_ports
}

module "ec2-add-trusted-ingress-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ec2.add_app_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/ec2/add-trusted-ingress"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  
  security_group_id             = local.default_public_app_sg
  trusted_attacker_source       = local.config.context.aws.ec2.add_app_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_target_source         = local.config.context.aws.ec2.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    local.target_eks_public_ip
  ]) : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.aws.ec2.add_app_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.config.context.aws.ec2.add_app_trusted_ingress.trusted_tcp_ports
}

##################################################
# AWS SSM
# ssm tag-based surface config
##################################################

module "ssh-keys" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/ssh-keys"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  ssh_public_key_path = local.config.context.aws.ssm.ssh_keys.ssh_public_key_path
  ssh_private_key_path = local.config.context.aws.ssm.ssh_keys.ssh_private_key_path
  ssh_authorized_keys_path = local.config.context.aws.ssm.ssh_keys.ssh_authorized_keys_path
}

module "ssh-user" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/ssh-user"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  username = local.config.context.aws.ssm.ssh_user.username
  password = local.config.context.aws.ssm.ssh_user.password
}

module "aws-credentials" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.aws_credentials.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/aws-credentials"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  compromised_credentials = var.compromised_credentials
  compromised_keys_user = local.config.context.aws.ssm.aws_credentials.compromised_keys_user
}

module "vulnerable-docker-log4shellapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.docker.log4shellapp.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/vulnerable/docker-log4shellapp"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  listen_port = local.config.context.aws.ssm.vulnerable.docker.log4shellapp.listen_port
}

module "vulnerable-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/vulnerable/log4j-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  listen_port = local.config.context.aws.ssm.vulnerable.log4j_app.listen_port
}

module "vulnerable-npm-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/vulnerable/npm-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  listen_port = local.config.context.aws.ssm.vulnerable.npm_app.listen_port
}

module "vulnerable-python3-twisted-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/vulnerable/python3-twisted-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  listen_port = local.config.context.aws.ssm.vulnerable.python3_twisted_app.listen_port
}

module "vulnerable-rds-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.vulnerable.rds_app.enabled == true ) ? 1 : 0
  source = "./modules/ssm/ec2/vulnerable/rds-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
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

# assign iam user cluster readonly role
module "eks-auth" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && (local.config.context.aws.eks.add_iam_user_readonly_user.enabled == true || local.config.context.aws.eks.add_iam_user_admin_user.enabled == true )) ? 1 : 0
  source      = "./modules/eks/eks-auth"
  environment       = local.config.context.global.environment
  deployment        = local.config.context.global.deployment
  cluster_name      = local.default_infrastructure_config.context.aws.eks.cluster_name

  # user here needs to be created by iam module
  iam_eks_readers = local.config.context.aws.eks.add_iam_user_readonly_user.iam_user_names
  iam_eks_admins = local.config.context.aws.eks.add_iam_user_admin_user.iam_user_names
  
  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.iam
  ]                    
}

##################################################
# Kubernetes General
##################################################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  
  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "kubernetes-app-windows" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.app-windows.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/app-windows"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.psp.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/psp"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

##################################################
# Kubernetes AWS Vulnerable
##################################################

module "vulnerable-kubernetes-voteapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.voteapp.enabled == true) ? 1 : 0
  source                        = "../kubernetes/aws/vulnerable/voteapp"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  region                        = local.default_infrastructure_config.context.aws.region
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
  secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

  vote_service_port             = local.config.context.kubernetes.aws.vulnerable.voteapp.vote_service_port
  result_service_port           = local.config.context.kubernetes.aws.vulnerable.voteapp.result_service_port
  trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.voteapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.voteapp.additional_trusted_sources

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "vulnerable-kubernetes-rdsapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.rdsapp.enabled == true ) ? 1 : 0
  source                              = "../kubernetes/aws/vulnerable/rdsapp"
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
  trusted_attacker_source             = local.config.context.kubernetes.aws.vulnerable.rdsapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source          = [module.workstation-external-ip.cidr]
  additional_trusted_sources          = local.config.context.kubernetes.aws.vulnerable.rdsapp.additional_trusted_sources

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "vulnerable-kubernetes-log4shellapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.log4shellapp.enabled == true ) ? 1 : 0
  source                        = "../kubernetes/aws/vulnerable/log4shellapp"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = local.config.context.kubernetes.aws.vulnerable.log4shellapp.service_port
  trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.log4shellapp.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.log4shellapp.additional_trusted_sources

  image                         = local.config.context.kubernetes.aws.vulnerable.log4shellapp.image
  command                       = local.config.context.kubernetes.aws.vulnerable.log4shellapp.command
  args                          = local.config.context.kubernetes.aws.vulnerable.log4shellapp.args

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "vulnerable-kubernetes-privileged-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/vulnerable/privileged-pod"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

  service_port                  = local.config.context.kubernetes.aws.vulnerable.privileged_pod.service_port
  trusted_attacker_source       = local.config.context.kubernetes.aws.vulnerable.privileged_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    local.attacker_eks_public_ip
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.kubernetes.aws.vulnerable.privileged_pod.additional_trusted_sources

  image                         = local.config.context.kubernetes.aws.vulnerable.privileged_pod.image
  command                       = local.config.context.kubernetes.aws.vulnerable.privileged_pod.command
  args                          = local.config.context.kubernetes.aws.vulnerable.privileged_pod.args

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.aws.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/aws/vulnerable/root-mount-fs-pod"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}
