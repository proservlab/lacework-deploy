##################################################
# LOCALS
##################################################

locals {
  target_infrastructure_config                = var.target_infrastructure_config
  target_kubeconfig                           = pathexpand("~/.kube/aws-target-${local.target_infrastructure_config.context.global.deployment}-kubeconfig")
  target_cluster_name                         = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster.id : null
  target_cluster_endpoint                     = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster.endpoint : null
  target_cluster_ca_cert                      = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster.certificate_authority[0].data : null
  target_cluster_oidc_issuer                  = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster.identity[0].oidc[0].issuer : null
  target_cluster_security_group               = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster_sg_id : null
  target_cluster_subnet                       = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster_subnet : null
  target_cluster_vpc_id                       = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster_vpc_id : null
  target_cluster_node_role_arn                = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster_node_role_arn : null
  target_cluster_vpc_subnet                   = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster_vpc_subnet : null
  target_cluster_openid_connect_provider_arn  = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster_openid_connect_provider.arn : null
  target_cluster_openid_connect_provider_url  = local.target_infrastructure_config.context.aws.eks.enabled ? module.target-eks[0].cluster_openid_connect_provider.url : null
  target_aws_profile_name                     = local.target_infrastructure_config.context.aws.profile_name
  target_aws_region                           = local.target_infrastructure_config.context.aws.region
}

##################################################
# AWS Lacework Audit & Config
##################################################

# lacework cloud audit and config collection
module "target-lacework-audit-config" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.lacework.aws_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/lacework-audit-config"
  environment = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
  
  use_existing_cloudtrail = local.target_infrastructure_config.context.lacework.aws_audit_config.use_existing_cloudtrail
  cloudtrail_name = local.target_infrastructure_config.context.lacework.aws_audit_config.cloudtrail_name
  use_existing_iam_role       = local.target_infrastructure_config.context.lacework.aws_audit_config.use_existing_iam_role
  create_lacework_integration = local.target_infrastructure_config.context.lacework.aws_audit_config.create_lacework_integration
  consolidated_trail = local.target_infrastructure_config.context.lacework.aws_audit_config.consolidated_trail
  is_organization_trail = local.target_infrastructure_config.context.lacework.aws_audit_config.is_organization_trail
  org_account_mappings = local.target_infrastructure_config.context.lacework.aws_audit_config.org_account_mappings
  use_existing_kms_key = local.target_infrastructure_config.context.lacework.aws_audit_config.use_existing_kms_key
  use_existing_iam_role_policy = local.target_infrastructure_config.context.lacework.aws_audit_config.use_existing_iam_role_policy
  iam_role_name = local.target_infrastructure_config.context.lacework.aws_audit_config.iam_role_name
  iam_role_arn = local.target_infrastructure_config.context.lacework.aws_audit_config.iam_role_arn
  iam_role_external_id = local.target_infrastructure_config.context.lacework.aws_audit_config.iam_role_external_id
  permission_boundary_arn = local.target_infrastructure_config.context.lacework.aws_audit_config.permission_boundary_arn
  external_id_length = local.target_infrastructure_config.context.lacework.aws_audit_config.external_id_length
  prefix = local.target_infrastructure_config.context.lacework.aws_audit_config.prefix
  enable_log_file_validation = local.target_infrastructure_config.context.lacework.aws_audit_config.enable_log_file_validation
  bucket_name = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_name
  bucket_arn = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_arn
  bucket_encryption_enabled = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_encryption_enabled
  bucket_logs_enabled = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_logs_enabled
  bucket_enable_mfa_delete = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_enable_mfa_delete
  bucket_versioning_enabled = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_versioning_enabled
  bucket_force_destroy = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_force_destroy
  bucket_sse_algorithm = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_sse_algorithm
  bucket_sse_key_arn = local.target_infrastructure_config.context.lacework.aws_audit_config.bucket_sse_key_arn
  log_bucket_name = local.target_infrastructure_config.context.lacework.aws_audit_config.log_bucket_name
  access_log_prefix = local.target_infrastructure_config.context.lacework.aws_audit_config.access_log_prefix
  s3_notification_log_prefix = local.target_infrastructure_config.context.lacework.aws_audit_config.s3_notification_log_prefix
  s3_notification_type = local.target_infrastructure_config.context.lacework.aws_audit_config.s3_notification_type
  sns_topic_arn = local.target_infrastructure_config.context.lacework.aws_audit_config.sns_topic_arn
  sns_topic_name = local.target_infrastructure_config.context.lacework.aws_audit_config.sns_topic_name
  sns_topic_encryption_key_arn = local.target_infrastructure_config.context.lacework.aws_audit_config.sns_topic_encryption_key_arn
  sns_topic_encryption_enabled = local.target_infrastructure_config.context.lacework.aws_audit_config.sns_topic_encryption_enabled
  sqs_queue_name = local.target_infrastructure_config.context.lacework.aws_audit_config.sqs_queue_name
  sqs_encryption_enabled = local.target_infrastructure_config.context.lacework.aws_audit_config.sqs_encryption_enabled
  sqs_encryption_key_arn = local.target_infrastructure_config.context.lacework.aws_audit_config.sqs_encryption_key_arn
  use_s3_bucket_notification = local.target_infrastructure_config.context.lacework.aws_audit_config.use_s3_bucket_notification
  use_existing_access_log_bucket = local.target_infrastructure_config.context.lacework.aws_audit_config.use_existing_access_log_bucket
  use_existing_sns_topic = local.target_infrastructure_config.context.lacework.aws_audit_config.use_existing_sns_topic
  cross_account_policy_name = local.target_infrastructure_config.context.lacework.aws_audit_config.cross_account_policy_name
  sqs_queues = local.target_infrastructure_config.context.lacework.aws_audit_config.sqs_queues
  lacework_integration_name = local.target_infrastructure_config.context.lacework.aws_audit_config.lacework_integration_name
  lacework_aws_account_id = local.target_infrastructure_config.context.lacework.aws_audit_config.lacework_aws_account_id
  wait_time = local.target_infrastructure_config.context.lacework.aws_audit_config.wait_time
  kms_key_rotation = local.target_infrastructure_config.context.lacework.aws_audit_config.kms_key_rotation
  kms_key_deletion_days = local.target_infrastructure_config.context.lacework.aws_audit_config.kms_key_deletion_days
  kms_key_multi_region = local.target_infrastructure_config.context.lacework.aws_audit_config.kms_key_multi_region
  enable_cloudtrail_s3_management_events = local.target_infrastructure_config.context.lacework.aws_audit_config.enable_cloudtrail_s3_management_events

  tags                       = merge(
    {
      environment = local.target_infrastructure_config.context.global.environment
      deployment = local.target_infrastructure_config.context.global.deployment
    }, 
    local.target_infrastructure_config.context.lacework.aws_audit_config.tags
  )

  providers = {
    lacework = lacework.target
    aws      = aws.target
  }
}

# lacework agentless scanning
module "target-lacework-agentless" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.lacework.aws_agentless.enabled == true ) ? 1 : 0
  source      = "./modules/lacework-agentless"
  environment = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  # attempt to use the existing vpc if possible (try default first then app if no vpc_id is provided)
  use_existing_vpc = local.target_infrastructure_config.context.lacework.aws_agentless.use_existing_vpc
  vpc_id = local.target_infrastructure_config.context.lacework.aws_agentless.use_existing_vpc == true ? (try(length(local.target_infrastructure_config.context.lacework.aws_agentless.vpc_id), "false") != "false" ? local.target_infrastructure_config.context.lacework.aws_agentless.vpc_id : try(module.target-ec2[0].public_vpc.id, module.target-ec2[0].public_app_vpc.id)) : ""
  # assume /16 for the public subnet and use x.x.100.0/24 as the network space for agentless
  vpc_cidr_block = local.target_infrastructure_config.context.lacework.aws_agentless.use_existing_vpc == true ? (try(length(local.target_infrastructure_config.context.lacework.aws_agentless.vpc_cidr_block), "false") != "false" ? local.target_infrastructure_config.context.lacework.vpc_cidr_block.vpc_id : cidrsubnet(try(module.target-ec2[0].public_vpc.cidr_block, module.target-ec2[0].public_app_vpc.cidr_block),8,100)) : "10.10.32.0/24"

  depends_on = [
    module.target-lacework-audit-config,
    module.target-ec2
  ]

  providers = {
    lacework = lacework.target
    aws      = aws.target
  }
}


##################################################
# AWS EC2
##################################################

# ec2
module "target-ec2" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ec2.enabled == true && can(length(local.target_infrastructure_config.context.aws.ec2.instances))) ? 1 : 0
  source       = "./modules/ec2"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  # list of instances to configure
  instances                           = [ for ec2 in local.target_infrastructure_config.context.aws.ec2.instances: { 
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
  trust_security_group                = local.target_infrastructure_config.context.global.trust_security_group

  public_ingress_rules                = local.target_infrastructure_config.context.aws.ec2.public_ingress_rules
  public_egress_rules                 = local.target_infrastructure_config.context.aws.ec2.public_egress_rules
  public_app_ingress_rules            = local.target_infrastructure_config.context.aws.ec2.public_app_ingress_rules
  public_app_egress_rules             = local.target_infrastructure_config.context.aws.ec2.public_app_egress_rules
  private_ingress_rules               = local.target_infrastructure_config.context.aws.ec2.private_ingress_rules
  private_egress_rules                = local.target_infrastructure_config.context.aws.ec2.private_egress_rules
  private_app_ingress_rules           = local.target_infrastructure_config.context.aws.ec2.private_app_ingress_rules
  private_app_egress_rules            = local.target_infrastructure_config.context.aws.ec2.private_app_egress_rules

  public_network                      = local.target_infrastructure_config.context.aws.ec2.public_network
  public_subnet                       = local.target_infrastructure_config.context.aws.ec2.public_subnet
  public_app_network                  = local.target_infrastructure_config.context.aws.ec2.public_app_network
  public_app_subnet                   = local.target_infrastructure_config.context.aws.ec2.public_app_subnet
  private_network                     = local.target_infrastructure_config.context.aws.ec2.private_network
  private_subnet                      = local.target_infrastructure_config.context.aws.ec2.private_subnet
  private_nat_subnet                  = local.target_infrastructure_config.context.aws.ec2.private_nat_subnet
  private_app_network                 = local.target_infrastructure_config.context.aws.ec2.private_app_network
  private_app_subnet                  = local.target_infrastructure_config.context.aws.ec2.private_app_subnet
  private_app_nat_subnet              = local.target_infrastructure_config.context.aws.ec2.private_app_nat_subnet

  enable_dynu_dns                     = local.target_infrastructure_config.context.dynu_dns.enabled
  dynu_dns_domain                     = local.target_infrastructure_config.context.dynu_dns.dns_domain
  dynu_dns_domain_id                  = local.target_infrastructure_config.context.dynu_dns.domain_id

  providers = {
    aws      = aws.target
    restapi  = restapi.target
  }
}

##################################################
# AWS EKS
##################################################

# eks
module "target-eks" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/eks"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
  region       = local.target_infrastructure_config.context.aws.region
  aws_profile_name = local.target_infrastructure_config.context.aws.profile_name

  cluster_name = local.target_infrastructure_config.context.aws.eks.cluster_name
  kubeconfig_path = local.target_kubeconfig

  deploy_calico = local.target_infrastructure_config.context.aws.eks.deploy_calico

  providers = {
    aws      = aws.target
  }
}

# eks
module "target-eks-windows" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks-windows.enabled == true ) ? 1 : 0
  source       = "./modules/eks-windows"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
  region       = local.target_infrastructure_config.context.aws.region
  aws_profile_name = local.target_infrastructure_config.context.aws.profile_name

  cluster_name = local.target_infrastructure_config.context.aws.eks-windows.cluster_name
  kubeconfig_path = local.target_kubeconfig

  providers = {
    aws      = aws.target
  }
}

#################################################
# EKS AUTOSCALER
#################################################

# eks-autoscale
module "target-eks-autoscaler" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/eks-autoscale"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
  region       = local.target_infrastructure_config.context.aws.region
  
  cluster_name = module.target-eks[0].cluster_name
  cluster_oidc_issuer = module.target-eks[0].cluster.identity[0].oidc[0].issuer

  providers = {
    aws = aws.target
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-eks-windows,
  ]
}

module "target-eks-windows-configmap" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks-windows.enabled == true ) ? 1 : 0
  source       = "./modules/eks-windows-configmap"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  cluster_name = module.target-eks-windows[0].cluster.id
  cluster_endpoint = module.target-eks-windows[0].cluster_endpoint
  cluster_ca_cert = module.target-eks-windows[0].cluster_ca_cert
  cluster_sg = module.target-eks-windows[0].cluster_sg_id
  cluster_subnet = module.target-eks-windows[0].cluster_subnet
  cluster_node_role_arn = module.target-eks-windows[0].cluster_node_role_arn

  providers = {
    aws = aws.target
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-eks-windows,
  ]
}

##################################################
# AWS EKS Calico
##################################################

module "target-eks-calico" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks.enabled == true && local.target_infrastructure_config.context.aws.eks.deploy_calico == true) ? 1 : 0
  source                                = "./modules/eks-calico"
  environment                           = local.target_infrastructure_config.context.global.environment
  deployment                            = local.target_infrastructure_config.context.global.deployment
  cluster_name                          = module.target-eks[0].cluster.id
  region                                = local.target_infrastructure_config.context.aws.region

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
  }

  depends_on = [
    module.target-eks,
    module.target-eks-windows,
    module.target-eks-autoscaler,
  ]
}

##################################################
# AWS EKS Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "target-lacework-daemonset" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/lacework-kubernetes-daemonset"
  environment                           = local.target_infrastructure_config.context.global.environment
  deployment                            = local.target_infrastructure_config.context.global.deployment
  cluster_name                          = module.target-eks[0].cluster.id
  
  lacework_agent_access_token           = local.target_infrastructure_config.context.lacework.agent.token
  lacework_server_url                   = local.target_infrastructure_config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.target_infrastructure_config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.target_infrastructure_config.context.aws.region

  syscall_config =  fileexists(var.target_lacework_sysconfig_path) ? file(var.target_lacework_sysconfig_path) : file(local.target_infrastructure_config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-eks,
    module.target-eks-windows,
    module.target-eks-autoscaler,
  ]
}

# lacework daemonset and kubernetes compliance
module "target-lacework-daemonset-windows" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks-windows.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.daemonset-windows.enabled == true  ) ? 1 : 0
  source                                = "./modules/lacework-kubernetes-daemonset-windows"
  environment                           = local.target_infrastructure_config.context.global.environment
  deployment                            = local.target_infrastructure_config.context.global.deployment
  cluster_name                          = module.target-eks[0].cluster.id
  lacework_agent_access_token           = local.target_infrastructure_config.context.lacework.agent.token
  lacework_server_url                   = local.target_infrastructure_config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = local.target_infrastructure_config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = local.target_infrastructure_config.context.aws.region

  syscall_config =  file(local.target_infrastructure_config.context.lacework.agent.kubernetes.daemonset-windows.syscall_config_path)

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-eks,
    module.target-eks-windows,
    module.target-eks-autoscaler,
  ]
}

# lacework kubernetes admission controller
module "target-lacework-admission-controller" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/lacework-kubernetes-admission-controller"
  environment                           = local.target_infrastructure_config.context.global.environment
  deployment                            = local.target_infrastructure_config.context.global.deployment
  cluster_name                          = module.target-eks[0].cluster.id
  
  lacework_account_name = local.target_infrastructure_config.context.lacework.account_name
  lacework_proxy_token  = local.target_infrastructure_config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-eks,
    module.target-eks-windows,
    module.target-eks-autoscaler,
  ]
}

# lacework eks audit
module "target-lacework-eks-audit" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.eks.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true  ) ? 1 : 0
  source      = "./modules/lacework-eks-audit"
  region                                = local.target_infrastructure_config.context.aws.region
  environment                           = local.target_infrastructure_config.context.global.environment
  deployment                            = local.target_infrastructure_config.context.global.deployment
  cluster_name                          = "${local.target_infrastructure_config.context.aws.eks.cluster_name}-${local.target_infrastructure_config.context.global.environment}-${local.target_infrastructure_config.context.global.deployment}"

  providers = {
    aws = aws.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-eks,
    module.target-eks-windows,
    module.target-eks-autoscaler,
  ]
}

##################################################
# AWS SSM 
##################################################

# ssm deploy inspector agent
module "target-ssm-deploy-inspector-agent" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_inspector_agent.enabled == true && local.target_infrastructure_config.context.aws.inspector.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-inspector-agent"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
}

# ssm deploy git
module "target-ssm-deploy-git" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_git.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-git"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.target
  }
}

# ssm deploy docker
module "target-ssm-deploy-docker" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_docker.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-docker"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
  
  docker_users = local.target_infrastructure_config.context.aws.ssm.deploy_docker.docker_users

  providers = {
    aws = aws.target
  }
}

# ssm deploy lacework agent
module "target-ssm-deploy-lacework-agent" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_lacework_agent.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-agent"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  lacework_agent_access_token = local.target_infrastructure_config.context.lacework.agent.token
  lacework_server_url         = local.target_infrastructure_config.context.lacework.server_url

  providers = {
    aws = aws.target
  }
}

# ssm deploy lacework syscall_config.yaml
module "target-lacework-ssm-deployment-syscall-config" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_lacework_syscall_config.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-syscall-config"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  syscall_config = var.target_lacework_sysconfig_path

  providers = {
    aws = aws.target
  }
}

module "target-ssm-deploy-lacework-code-aware-agent" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_lacework_code_aware_agent.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-code-aware-agent"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.target
  }
}

# ssm deploy aws cli
module "target-ssm-deploy-aws-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_aws_cli.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-aws-cli"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.target
  }
}

# ssm deploy lacework cli
module "target-ssm-deploy-lacework-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_lacework_cli.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-cli"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.target
  }
}

# ssm deploy kubectl cli
module "target-ssm-deploy-kubectl-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_kubectl_cli.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-kubectl-cli"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  providers = {
    aws = aws.target
  }
}

# ssm deploy protonvpn docker
module "target-ssm-deploy-protonvpn-docker" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.ssm.deploy_protonvpn_docker.enabled == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-protonvpn-docker"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
  protonvpn_user = var.target_protonvpn_user
  protonvpn_password = var.target_protonvpn_password
  protonvpn_tier = var.target_protonvpn_tier
  protonvpn_server = var.target_protonvpn_server
  protonvpn_protocol = var.target_protonvpn_protocol

  providers = {
    aws = aws.target
  }
}

##################################################
# AWS RDS
##################################################

module "target-rds" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.aws.ssm.enabled == true && local.target_infrastructure_config.context.aws.rds.enabled == true ) ? 1 : 0
  source = "./modules/rds"
  environment                   = local.target_infrastructure_config.context.global.environment
  deployment                    = local.target_infrastructure_config.context.global.deployment
  region                        = local.target_infrastructure_config.context.aws.region
  
  igw_id                        = module.target-ec2[0].public_app_igw.id
  vpc_id                        = module.target-ec2[0].public_app_vpc.id
  vpc_subnet                    = module.target-ec2[0].public_app_network
  ec2_instance_role_name        = module.target-ec2[0].ec2_instance_app_role.name
  user_role_name                = local.target_infrastructure_config.context.aws.rds.user_role_name
  instance_type                 = local.target_infrastructure_config.context.aws.rds.instance_type
  trusted_sg_id                 = module.target-ec2[0].public_app_sg.id

  depends_on = [
    module.target-ec2
  ]

  providers = {
    aws = aws.target
  }
}