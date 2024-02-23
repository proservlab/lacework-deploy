##################################################
# LOCALS
##################################################

locals {
  attacker_infrastructure_config                = var.attacker_infrastructure_config
  attacker_kubeconfig                           = pathexpand("~/.kube/aws-attacker-${local.attacker_infrastructure_config.context.global.deployment}-kubeconfig")
  attacker_cluster_name                         = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster.id : null
  attacker_cluster_endpoint                     = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster.endpoint : null
  attacker_cluster_ca_cert                      = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster.certificate_authority[0].data : null
  attacker_cluster_oidc_issuer                  = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster.identity[0].oidc[0].issuer : null
  attacker_cluster_security_group               = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster_sg_id : null
  attacker_cluster_vpc_id                       = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster_vpc_id : null
  attacker_cluster_vpc_subnet                   = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster_vpc_subnet : null
  attacker_cluster_openid_connect_provider_arn  = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster_openid_connect_provider.arn : null
  attacker_cluster_openid_connect_provider_url  = local.attacker_infrastructure_config.context.aws.eks.enabled ? module.attacker-eks[0].cluster_openid_connect_provider.url : null
  attacker_aws_profile_name                     = local.attacker_infrastructure_config.context.aws.profile_name
  attacker_aws_region                           = local.attacker_infrastructure_config.context.aws.region
}

##################################################
# AWS Lacework Audit & Config
##################################################

# lacework cloud audit and config collection
module "attacker-lacework-audit-config" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.lacework.aws_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/lacework-audit-config"
  environment = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment
  
  use_existing_cloudtrail = local.attacker_infrastructure_config.context.lacework.aws_audit_config.use_existing_cloudtrail
  cloudtrail_name = local.attacker_infrastructure_config.context.lacework.aws_audit_config.cloudtrail_name
  use_existing_iam_role       = local.attacker_infrastructure_config.context.lacework.aws_audit_config.use_existing_iam_role
  create_lacework_integration = local.attacker_infrastructure_config.context.lacework.aws_audit_config.create_lacework_integration
  consolidated_trail = local.attacker_infrastructure_config.context.lacework.aws_audit_config.consolidated_trail
  is_organization_trail = local.attacker_infrastructure_config.context.lacework.aws_audit_config.is_organization_trail
  org_account_mappings = local.attacker_infrastructure_config.context.lacework.aws_audit_config.org_account_mappings
  use_existing_kms_key = local.attacker_infrastructure_config.context.lacework.aws_audit_config.use_existing_kms_key
  use_existing_iam_role_policy = local.attacker_infrastructure_config.context.lacework.aws_audit_config.use_existing_iam_role_policy
  iam_role_name = local.attacker_infrastructure_config.context.lacework.aws_audit_config.iam_role_name
  iam_role_arn = local.attacker_infrastructure_config.context.lacework.aws_audit_config.iam_role_arn
  iam_role_external_id = local.attacker_infrastructure_config.context.lacework.aws_audit_config.iam_role_external_id
  permission_boundary_arn = local.attacker_infrastructure_config.context.lacework.aws_audit_config.permission_boundary_arn
  external_id_length = local.attacker_infrastructure_config.context.lacework.aws_audit_config.external_id_length
  prefix = local.attacker_infrastructure_config.context.lacework.aws_audit_config.prefix
  enable_log_file_validation = local.attacker_infrastructure_config.context.lacework.aws_audit_config.enable_log_file_validation
  bucket_name = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_name
  bucket_arn = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_arn
  bucket_encryption_enabled = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_encryption_enabled
  bucket_logs_enabled = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_logs_enabled
  bucket_enable_mfa_delete = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_enable_mfa_delete
  bucket_versioning_enabled = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_versioning_enabled
  bucket_force_destroy = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_force_destroy
  bucket_sse_algorithm = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_sse_algorithm
  bucket_sse_key_arn = local.attacker_infrastructure_config.context.lacework.aws_audit_config.bucket_sse_key_arn
  log_bucket_name = local.attacker_infrastructure_config.context.lacework.aws_audit_config.log_bucket_name
  access_log_prefix = local.attacker_infrastructure_config.context.lacework.aws_audit_config.access_log_prefix
  s3_notification_log_prefix = local.attacker_infrastructure_config.context.lacework.aws_audit_config.s3_notification_log_prefix
  s3_notification_type = local.attacker_infrastructure_config.context.lacework.aws_audit_config.s3_notification_type
  sns_topic_arn = local.attacker_infrastructure_config.context.lacework.aws_audit_config.sns_topic_arn
  sns_topic_name = local.attacker_infrastructure_config.context.lacework.aws_audit_config.sns_topic_name
  sns_topic_encryption_key_arn = local.attacker_infrastructure_config.context.lacework.aws_audit_config.sns_topic_encryption_key_arn
  sns_topic_encryption_enabled = local.attacker_infrastructure_config.context.lacework.aws_audit_config.sns_topic_encryption_enabled
  sqs_queue_name = local.attacker_infrastructure_config.context.lacework.aws_audit_config.sqs_queue_name
  sqs_encryption_enabled = local.attacker_infrastructure_config.context.lacework.aws_audit_config.sqs_encryption_enabled
  sqs_encryption_key_arn = local.attacker_infrastructure_config.context.lacework.aws_audit_config.sqs_encryption_key_arn
  use_s3_bucket_notification = local.attacker_infrastructure_config.context.lacework.aws_audit_config.use_s3_bucket_notification
  use_existing_access_log_bucket = local.attacker_infrastructure_config.context.lacework.aws_audit_config.use_existing_access_log_bucket
  use_existing_sns_topic = local.attacker_infrastructure_config.context.lacework.aws_audit_config.use_existing_sns_topic
  cross_account_policy_name = local.attacker_infrastructure_config.context.lacework.aws_audit_config.cross_account_policy_name
  sqs_queues = local.attacker_infrastructure_config.context.lacework.aws_audit_config.sqs_queues
  lacework_integration_name = local.attacker_infrastructure_config.context.lacework.aws_audit_config.lacework_integration_name
  lacework_aws_account_id = local.attacker_infrastructure_config.context.lacework.aws_audit_config.lacework_aws_account_id
  wait_time = local.attacker_infrastructure_config.context.lacework.aws_audit_config.wait_time
  kms_key_rotation = local.attacker_infrastructure_config.context.lacework.aws_audit_config.kms_key_rotation
  kms_key_deletion_days = local.attacker_infrastructure_config.context.lacework.aws_audit_config.kms_key_deletion_days
  kms_key_multi_region = local.attacker_infrastructure_config.context.lacework.aws_audit_config.kms_key_multi_region
  enable_cloudtrail_s3_management_events = local.attacker_infrastructure_config.context.lacework.aws_audit_config.enable_cloudtrail_s3_management_events

  tags                       = merge(
    {
      environment = local.attacker_infrastructure_config.context.global.environment
      deployment = local.attacker_infrastructure_config.context.global.deployment
    }, 
    local.attacker_infrastructure_config.context.lacework.aws_audit_config.tags
  )

  providers = {
    lacework = lacework.attacker
    aws      = aws.attacker
  }
}

# lacework agentless scanning
module "attacker-lacework-agentless" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.lacework.aws_agentless.enabled == true ) ? 1 : 0
  source      = "./modules/lacework-agentless"
  environment = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  # attempt to use the existing vpc if possible (try default first then app if no vpc_id is provided)
  use_existing_vpc = local.attacker_infrastructure_config.context.lacework.aws_agentless.use_existing_vpc
  vpc_id = local.attacker_infrastructure_config.context.lacework.aws_agentless.use_existing_vpc == true ? (try(length(local.attacker_infrastructure_config.context.lacework.aws_agentless.vpc_id), "false") != "false" ? local.attacker_infrastructure_config.context.lacework.aws_agentless.vpc_id : try(module.attacker-ec2[0].public_vpc.id, module.attacker-ec2[0].public_app_vpc.id)) : ""
  # assume /16 for the public subnet and use x.x.100.0/24 as the network space for agentless
  vpc_cidr_block = local.attacker_infrastructure_config.context.lacework.aws_agentless.use_existing_vpc == true ? (try(length(local.attacker_infrastructure_config.context.lacework.aws_agentless.vpc_cidr_block), "false") != "false" ? local.attacker_infrastructure_config.context.lacework.vpc_cidr_block.vpc_id : cidrsubnet(try(module.attacker-ec2[0].public_vpc.cidr_block, module.attacker-ec2[0].public_app_vpc.cidr_block),8,100)) : "10.10.32.0/24"

  depends_on = [
    module.attacker-lacework-audit-config,
    module.attacker-ec2
  ]

  providers = {
    lacework = lacework.attacker
    aws      = aws.attacker
  }
}


##################################################
# AWS EC2
##################################################

# ec2
module "attacker-ec2" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ec2.enabled == true && can(length(local.attacker_infrastructure_config.context.aws.ec2.instances))) ? 1 : 0
  source       = "./modules/ec2"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  # list of instances to configure
  instances                           = [ for ec2 in local.attacker_infrastructure_config.context.aws.ec2.instances: { 
      name                            = lookup(ec2, "name", "default-name")
      public                          = lookup(ec2, "public", true)
      role                            = lookup(ec2, "role", "default")
      instance_type                   = lookup(ec2, "instance_type", "t2.micro")
      enable_secondary_volume         = lookup(ec2, "enable_secondary_volume", false)
      enable_swap                     = lookup(ec2, "enable_swap", true)
      ami_name                        = lookup(ec2, "ami_name", "ubuntu_focal")
      tags                            = lookup(ec2, "tags", {})
      user_data                       = lookup(ec2, "user_data", null)
      user_data_base64                = lookup(ec2, "user_data_base64", null)
    } ]

  # allow endpoints inside their own security group to communicate
  trust_security_group                = local.attacker_infrastructure_config.context.global.trust_security_group

  public_ingress_rules                = local.attacker_infrastructure_config.context.aws.ec2.public_ingress_rules
  public_egress_rules                 = local.attacker_infrastructure_config.context.aws.ec2.public_egress_rules
  public_app_ingress_rules            = local.attacker_infrastructure_config.context.aws.ec2.public_app_ingress_rules
  public_app_egress_rules             = local.attacker_infrastructure_config.context.aws.ec2.public_app_egress_rules
  private_ingress_rules               = local.attacker_infrastructure_config.context.aws.ec2.private_ingress_rules
  private_egress_rules                = local.attacker_infrastructure_config.context.aws.ec2.private_egress_rules
  private_app_ingress_rules           = local.attacker_infrastructure_config.context.aws.ec2.private_app_ingress_rules
  private_app_egress_rules            = local.attacker_infrastructure_config.context.aws.ec2.private_app_egress_rules

  public_network                      = local.attacker_infrastructure_config.context.aws.ec2.public_network
  public_subnet                       = local.attacker_infrastructure_config.context.aws.ec2.public_subnet
  public_app_network                  = local.attacker_infrastructure_config.context.aws.ec2.public_app_network
  public_app_subnet                   = local.attacker_infrastructure_config.context.aws.ec2.public_app_subnet
  private_network                     = local.attacker_infrastructure_config.context.aws.ec2.private_network
  private_subnet                      = local.attacker_infrastructure_config.context.aws.ec2.private_subnet
  private_nat_subnet                  = local.attacker_infrastructure_config.context.aws.ec2.private_nat_subnet
  private_app_network                 = local.attacker_infrastructure_config.context.aws.ec2.private_app_network
  private_app_subnet                  = local.attacker_infrastructure_config.context.aws.ec2.private_app_subnet
  private_app_nat_subnet              = local.attacker_infrastructure_config.context.aws.ec2.private_app_nat_subnet

  enable_dynu_dns                     = local.attacker_infrastructure_config.context.dynu_dns.enabled
  dynu_dns_domain                     = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  dynu_api_key                        = local.attacker_infrastructure_config.context.dynu_dns.api_key

  providers = {
    aws      = aws.attacker
    restapi  = restapi.main
  }
}

##################################################
# AWS EKS
##################################################

# eks
module "attacker-eks" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/eks"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment
  region       = local.attacker_infrastructure_config.context.aws.region
  aws_profile_name = local.attacker_infrastructure_config.context.aws.profile_name

  cluster_name = local.attacker_infrastructure_config.context.aws.eks.cluster_name
  kubeconfig_path = local.attacker_kubeconfig

  deploy_calico = local.attacker_infrastructure_config.context.aws.eks.deploy_calico

  providers = {
    aws = aws.attacker
  }
}

# eks
module "attacker-eks-windows" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks-windows.enabled == true ) ? 1 : 0
  source       = "./modules/eks-windows"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment
  region       = local.attacker_infrastructure_config.context.aws.region
  aws_profile_name = local.attacker_infrastructure_config.context.aws.profile_name

  cluster_name = local.attacker_infrastructure_config.context.aws.eks-windows.cluster_name
  kubeconfig_path = local.attacker_kubeconfig

  providers = {
    aws = aws.attacker
  }
}

#################################################
# EKS AUTOSCALER
#################################################

# eks-autoscale
module "attacker-eks-autoscaler" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/eks-autoscale"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment
  region       = local.attacker_infrastructure_config.context.aws.region
  
  cluster_name = module.attacker-eks[0].cluster_name
  cluster_oidc_issuer = module.attacker-eks[0].cluster.identity[0].oidc[0].issuer

  providers = {
    aws = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
  }

  depends_on = [
    module.attacker-eks,
    module.attacker-eks-windows,
  ]
}

module "attacker-eks-windows-configmap" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks-windows.enabled == true ) ? 1 : 0
  source       = "./modules/eks-windows-configmap"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  cluster_name = module.attacker-eks-windows[0].cluster.id
  cluster_endpoint = module.attacker-eks-windows[0].cluster_endpoint
  cluster_ca_cert = module.attacker-eks-windows[0].cluster_ca_cert
  cluster_sg = module.attacker-eks-windows[0].cluster_sg_id
  cluster_subnet = module.attacker-eks-windows[0].cluster_subnet
  cluster_node_role_arn = module.attacker-eks-windows[0].cluster_node_role_arn

  providers = {
    aws = aws.attacker
    kubernetes = kubernetes.attacker
    helm = helm.attacker
  }

  depends_on = [
    module.attacker-eks,
    module.attacker-eks-windows,
  ]
}

##################################################
# AWS EKS Calico
##################################################

module "attacker-eks-calico" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks.enabled == true && local.attacker_infrastructure_config.context.aws.eks.deploy_calico == true) ? 1 : 0
  source                                = "./modules/eks-calico"
  environment                           = local.attacker_infrastructure_config.context.global.environment
  deployment                            = local.attacker_infrastructure_config.context.global.deployment
  cluster_name                          = module.attacker-eks[0].cluster.id
  region                                = local.attacker_infrastructure_config.context.aws.region

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
  }

  depends_on = [
    module.attacker-eks,
    module.attacker-eks-windows,
    module.attacker-eks-autoscaler,
  ]
}

##################################################
# AWS EKS Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "attacker-lacework-daemonset" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/lacework-kubernetes-daemonset"
  environment                           = local.attacker_infrastructure_config.context.global.environment
  deployment                            = local.attacker_infrastructure_config.context.global.deployment
  cluster_name                          = module.attacker-eks[0].cluster.id
  
  lacework_agent_access_token           = local.attacker_infrastructure_config.context.lacework.agent.token
  lacework_server_url                   = local.attacker_infrastructure_config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.attacker_infrastructure_config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.attacker_infrastructure_config.context.aws.region

  syscall_config =  fileexists(var.attacker_lacework_sysconfig_path) ? file(var.attacker_lacework_sysconfig_path) : file(local.attacker_infrastructure_config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    lacework = lacework.attacker
  }

  depends_on = [
    module.attacker-eks,
    module.attacker-eks-windows,
    module.attacker-eks-autoscaler,
  ]
}

# lacework daemonset and kubernetes compliance
module "attacker-lacework-daemonset-windows" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks-windows.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.daemonset-windows.enabled == true  ) ? 1 : 0
  source                                = "./modules/lacework-kubernetes-daemonset-windows"
  environment                           = local.attacker_infrastructure_config.context.global.environment
  deployment                            = local.attacker_infrastructure_config.context.global.deployment
  cluster_name                          = module.attacker-eks[0].cluster.id
  lacework_agent_access_token           = local.attacker_infrastructure_config.context.lacework.agent.token
  lacework_server_url                   = local.attacker_infrastructure_config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.attacker_infrastructure_config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.attacker_infrastructure_config.context.aws.region

  syscall_config =  file(local.attacker_infrastructure_config.context.lacework.agent.kubernetes.daemonset-windows.syscall_config_path)

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    lacework = lacework.attacker
  }

  depends_on = [
    module.attacker-eks,
    module.attacker-eks-windows,
    module.attacker-eks-autoscaler,
  ]
}

# lacework kubernetes admission controller
module "attacker-lacework-admission-controller" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/lacework-kubernetes-admission-controller"
  environment                           = local.attacker_infrastructure_config.context.global.environment
  deployment                            = local.attacker_infrastructure_config.context.global.deployment
  cluster_name                          = module.attacker-eks[0].cluster.id
  
  lacework_account_name = local.attacker_infrastructure_config.context.lacework.account_name
  lacework_proxy_token  = local.attacker_infrastructure_config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    lacework = lacework.attacker
  }

  depends_on = [
    module.attacker-eks,
    module.attacker-eks-windows,
    module.attacker-eks-autoscaler,
  ]
}

# lacework eks audit
module "attacker-lacework-eks-audit" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.eks.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true  ) ? 1 : 0
  source      = "./modules/lacework-eks-audit"
  region                                = local.attacker_infrastructure_config.context.aws.region
  environment                           = local.attacker_infrastructure_config.context.global.environment
  deployment                            = local.attacker_infrastructure_config.context.global.deployment
  cluster_name                          = "${local.attacker_infrastructure_config.context.aws.eks.cluster_name}-${local.attacker_infrastructure_config.context.global.environment}-${local.attacker_infrastructure_config.context.global.deployment}"

  providers = {
    aws = aws.attacker
    lacework = lacework.attacker
  }

  depends_on = [
    module.attacker-eks,
    module.attacker-eks-windows,
    module.attacker-eks-autoscaler,
  ]
}

##################################################
# AWS SSM 
##################################################

# ssm deploy inspector agent
module "attacker-ssm-deploy-inspector-agent" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_inspector_agent.enabled == true && local.attacker_infrastructure_config.context.aws.inspector.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-inspector-agent"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.attacker
  }
}

# ssm deploy git
module "attacker-ssm-deploy-git" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_git.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-git"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.attacker
  }
}

# ssm deploy docker
module "attacker-ssm-deploy-docker" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_docker.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-docker"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment
  
  docker_users = local.attacker_infrastructure_config.context.aws.ssm.deploy_docker.docker_users

  providers = {
    aws = aws.attacker
  }
}

# ssm deploy lacework agent
module "attacker-ssm-deploy-lacework-agent" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_lacework_agent.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-agent"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  lacework_agent_access_token = local.attacker_infrastructure_config.context.lacework.agent.token
  lacework_server_url         = local.attacker_infrastructure_config.context.lacework.server_url

  providers = {
    aws = aws.attacker
    lacework = lacework.target
  }
}

# ssm deploy lacework syscall_config.yaml
module "attacker-lacework-ssm-deployment-syscall-config" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_lacework_syscall_config.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-syscall-config"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  syscall_config = var.attacker_lacework_sysconfig_path

  providers = {
    aws = aws.attacker
  }
}

module "attacker-ssm-deploy-lacework-code-aware-agent" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_lacework_code_aware_agent.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-code-aware-agent"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.attacker
  }
}

# ssm deploy aws cli
module "attacker-ssm-deploy-aws-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_aws_cli.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-aws-cli"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.attacker
  }
}

# ssm deploy lacework cli
module "attacker-ssm-deploy-lacework-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_lacework_cli.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-cli"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.attacker
  }
}

# ssm deploy kubectl cli
module "attacker-ssm-deploy-kubectl-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_kubectl_cli.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-kubectl-cli"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.attacker
  }
}

# ssm deploy protonvpn docker
module "attacker-ssm-deploy-protonvpn-docker" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.ssm.deploy_protonvpn_docker.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-protonvpn-docker"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment
  protonvpn_user = var.attacker_protonvpn_user
  protonvpn_password = var.attacker_protonvpn_password
  protonvpn_tier = var.attacker_protonvpn_tier
  protonvpn_server = var.attacker_protonvpn_server
  protonvpn_protocol = var.attacker_protonvpn_protocol

  providers = {
    aws = aws.attacker
  }
}

##################################################
# AWS RDS
##################################################

module "attacker-rds" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.aws.ssm.enabled == true && local.attacker_infrastructure_config.context.aws.rds.enabled == true ) ? 1 : 0
  source = "./modules/rds"
  environment                   = local.attacker_infrastructure_config.context.global.environment
  deployment                    = local.attacker_infrastructure_config.context.global.deployment
  region                        = local.attacker_infrastructure_config.context.aws.region
  
  igw_id                        = module.attacker-ec2[0].public_app_igw.id
  vpc_id                        = module.attacker-ec2[0].public_app_vpc.id
  vpc_subnet                    = module.attacker-ec2[0].public_app_network
  ec2_instance_role_name        = module.attacker-ec2[0].ec2_instance_app_role.name
  user_role_name                = local.attacker_infrastructure_config.context.aws.rds.user_role_name
  instance_type                 = local.attacker_infrastructure_config.context.aws.rds.instance_type
  trusted_sg_id                 = module.attacker-ec2[0].public_app_sg.id

  providers = {
    aws = aws.attacker
  }

  depends_on = [
    module.attacker-ec2
  ]
}