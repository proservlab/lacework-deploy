##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../context/deployment"
}

##################################################
# LOCALS
##################################################

module "default-config" {
  source = "../../context/infrastructure"
}

locals {
  config = try(length(var.config), {}) == {} ? module.default-config.config : var.config
  default_infrastructure_config = try(length(var.config), {}) == {} ? module.default-config.config : var.config

  cluster_name                        = try(module.eks[0].cluster.id, "cluster")
  cluster_endpoint                    = try(module.eks[0].cluster.endpoint, null)
  cluster_ca_cert                     = try(module.eks[0].cluster.certificate_authority[0].data, null)
  cluster_oidc_issuer                 = try(module.eks[0].cluster.identity[0].oidc[0].issuer, null)
  cluster_security_group              = try(module.eks[0].cluster_sg_id, null)
  cluster_subnet                      = try(module.eks[0].cluster_subnet, null)
  cluster_vpc_id                      = try(module.eks[0].cluster_vpc_id, null)
  cluster_node_role_arn               = try(module.eks[0].cluster_node_role_arn, null)
  cluster_vpc_subnet                  = try(module.eks[0].cluster_vpc_subnet, null)
  cluster_openid_connect_provider_arn = try(module.eks[0].cluster_openid_connect_provider.arn, null)
  cluster_openid_connect_provider_url = try(module.eks[0].cluster_openid_connect_provider.url, null)

  aws_profile_name = local.default_infrastructure_config.context.aws.profile_name
  aws_region = local.default_infrastructure_config.context.aws.region
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
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AWS Lacework Audit & Config
##################################################

# lacework cloud audit and config collection
module "lacework-audit-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.aws_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/audit-config"
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

resource "time_sleep" "lacework_wait_90" {
  create_duration = "90s"
  depends_on = [
    module.lacework-audit-config,
  ]
}

# lacework agentless scanning
module "lacework-agentless" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.aws_agentless.enabled == true ) ? 1 : 0
  source      = "./modules/agentless"
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  depends_on = [
    time_sleep.lacework_wait_90,
    module.lacework-audit-config
  ]
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
  instances                           = [ for ec2 in local.config.context.aws.ec2.instances: { 
      name                            = lookup(ec2, "name", "default-name")
      public                          = lookup(ec2, "public", true)
      role                            = lookup(ec2, "role", "default")
      instance_type                   = lookup(ec2, "instance_type", "t2.micro")
      enable_secondary_volume         = lookup(ec2, "enable_secondary_volume", false)
      ami_name                        = lookup(ec2, "ami_name", "ubuntu_focal")
      tags                            = lookup(ec2, "tags", {})
      user_data                       = lookup(ec2, "user_data", null)
      user_data_base64                = lookup(ec2, "user_data_base64", null)
    } ]

  # allow endpoints inside their own security group to communicate
  trust_security_group                = local.config.context.global.trust_security_group

  public_ingress_rules                = local.config.context.aws.ec2.public_ingress_rules
  public_egress_rules                 = local.config.context.aws.ec2.public_egress_rules
  public_app_ingress_rules            = local.config.context.aws.ec2.public_app_ingress_rules
  public_app_egress_rules             = local.config.context.aws.ec2.public_app_egress_rules
  private_ingress_rules               = local.config.context.aws.ec2.private_ingress_rules
  private_egress_rules                = local.config.context.aws.ec2.private_egress_rules
  private_app_ingress_rules           = local.config.context.aws.ec2.private_app_ingress_rules
  private_app_egress_rules            = local.config.context.aws.ec2.private_app_egress_rules

  public_network                      = local.config.context.aws.ec2.public_network
  public_subnet                       = local.config.context.aws.ec2.public_subnet
  public_app_network                  = local.config.context.aws.ec2.public_app_network
  public_app_subnet                   = local.config.context.aws.ec2.public_app_subnet
  private_network                     = local.config.context.aws.ec2.private_network
  private_subnet                      = local.config.context.aws.ec2.private_subnet
  private_nat_subnet                  = local.config.context.aws.ec2.private_nat_subnet
  private_app_network                 = local.config.context.aws.ec2.private_app_network
  private_app_subnet                  = local.config.context.aws.ec2.private_app_subnet
  private_app_nat_subnet              = local.config.context.aws.ec2.private_app_nat_subnet

  enable_dynu_dns                     = local.config.context.dynu_dns.enabled
  dynu_dns_domain                     = local.config.context.dynu_dns.dns_domain

  depends_on = [
    time_sleep.lacework_wait_90
  ]
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
  kubeconfig_path = var.default_kubeconfig
}

# eks
module "eks-windows" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks-windows.enabled == true ) ? 1 : 0
  source       = "./modules/eks-windows"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.aws.region
  aws_profile_name = local.config.context.aws.profile_name

  cluster_name = local.config.context.aws.eks-windows.cluster_name
  kubeconfig_path = var.default_kubeconfig
}

#################################################
# EKS WAIT
#################################################

resource "null_resource" "eks_wait" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
                set -e
                if [ "cluster" != "${ local.cluster_name }" ]; then
                  echo 'Wait for kubernetes...'
                  aws eks wait cluster-active --profile '${local.aws_profile_name}' --name '${local.cluster_name}'
                fi;
              EOT
  }

  depends_on = [
    time_sleep.lacework_wait_90,
    module.eks,
    module.eks-windows
  ]
}

resource "time_sleep" "wait_30" {
  create_duration = "30s"

  depends_on = [
    null_resource.eks_wait
  ]
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

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }


  depends_on = [
    module.eks-windows,
    module.eks,
    time_sleep.wait_30
  ]
}

module "eks-windows-configmap" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks-windows.enabled == true ) ? 1 : 0
  source       = "./modules/eks-windows-configmap"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  cluster_name = local.config.context.aws.eks-windows.cluster_name
  cluster_endpoint = module.eks-windows[0].cluster_endpoint
  cluster_ca_cert = module.eks-windows[0].cluster_ca_cert
  cluster_sg = module.eks-windows[0].cluster_sg_id
  cluster_subnet = module.eks-windows[0].cluster_subnet
  cluster_node_role_arn = module.eks-windows[0].cluster_node_role_arn

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
    time_sleep.wait_30
  ]
}

##################################################
# AWS EKS Lacework
##################################################

module "lacework-namespace" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && ( local.config.context.aws.eks.enabled == true || local.config.context.aws.eks-windows.enabled == true) && (local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true || local.config.context.lacework.agent.kubernetes.daemonset.enabled == true || local.config.context.lacework.agent.kubernetes.daemonset-windows.enabled == true || local.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true )  ) ? 1 : 0
  source                                = "./modules/kubernetes/namespace"
  
  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
    time_sleep.wait_30
  ]
}

# lacework daemonset and kubernetes compliance
module "lacework-daemonset" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/kubernetes/daemonset"
  cluster_name                          = "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  lacework_agent_access_token           = local.config.context.lacework.agent.token
  lacework_server_url                   = local.config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.config.context.aws.region

  syscall_config =  fileexists(var.default_lacework_sysconfig_path) ? file(var.default_lacework_sysconfig_path) : file(local.config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
    time_sleep.wait_30,
    module.lacework-namespace
  ]
}

# lacework daemonset and kubernetes compliance
module "lacework-daemonset-windows" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks-windows.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset-windows.enabled == true  ) ? 1 : 0
  source                                = "./modules/kubernetes/daemonset-windows"
  cluster_name                          = "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  lacework_agent_access_token           = local.config.context.lacework.agent.token
  lacework_server_url                   = local.config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.config.context.aws.region

  syscall_config =  file(local.config.context.lacework.agent.kubernetes.daemonset-windows.syscall_config_path)

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
    time_sleep.wait_30,
    module.lacework-namespace
  ]
}

# lacework kubernetes admission controller
module "lacework-admission-controller" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/kubernetes/admission-controller"
  environment           = local.config.context.global.environment
  deployment            = local.config.context.global.deployment
  
  lacework_account_name = local.config.context.lacework.account_name
  lacework_proxy_token  = local.config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
    time_sleep.wait_30,
    module.lacework-namespace
  ]
}

# lacework eks audit
module "lacework-eks-audit" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true  ) ? 1 : 0
  source      = "./modules/eks-audit"
  region      = local.config.context.aws.region
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  cluster_names = [
    "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
  ]

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
    time_sleep.wait_30,
    module.lacework-namespace
  ]
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

  syscall_config = fileexists(var.default_lacework_sysconfig_path) ? var.default_lacework_sysconfig_path : "${path.module}/modules/ssm/deploy-lacework-syscall-config/resources/syscall_config.yaml"
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