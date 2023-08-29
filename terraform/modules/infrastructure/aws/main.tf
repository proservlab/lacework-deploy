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
  
  use_existing_cloudtrail = local.config.context.lacework.aws_audit_config.use_existing_cloudtrail
  cloudtrail_name = try(length(local.config.context.lacework.aws_audit_config.cloudtrail_name),"false") != "false" ? local.config.context.lacework.aws_audit_config.cloudtrail_name : "lacework-cloudtrail-${replace(local.config.context.global.environment,"_","-")}-${replace(local.config.context.global.deployment,"_","-")}"
  use_existing_iam_role       = local.config.context.lacework.aws_audit_config.use_existing_iam_role
  create_lacework_integration = local.config.context.lacework.aws_audit_config.create_lacework_integration
  consolidated_trail = local.config.context.lacework.aws_audit_config.consolidated_trail
  is_organization_trail = local.config.context.lacework.aws_audit_config.is_organization_trail
  org_account_mappings = local.config.context.lacework.aws_audit_config.org_account_mappings
  use_existing_kms_key = local.config.context.lacework.aws_audit_config.use_existing_kms_key
  use_existing_iam_role_policy = local.config.context.lacework.aws_audit_config.use_existing_iam_role_policy
  iam_role_name = local.config.context.lacework.aws_audit_config.iam_role_name
  iam_role_arn = local.config.context.lacework.aws_audit_config.iam_role_arn
  iam_role_external_id = local.config.context.lacework.aws_audit_config.iam_role_external_id
  permission_boundary_arn = local.config.context.lacework.aws_audit_config.permission_boundary_arn
  external_id_length = local.config.context.lacework.aws_audit_config.external_id_length
  prefix = local.config.context.lacework.aws_audit_config.prefix
  enable_log_file_validation = local.config.context.lacework.aws_audit_config.enable_log_file_validation
  bucket_name = local.config.context.lacework.aws_audit_config.bucket_name
  bucket_arn = local.config.context.lacework.aws_audit_config.bucket_arn
  bucket_encryption_enabled = local.config.context.lacework.aws_audit_config.bucket_encryption_enabled
  bucket_logs_enabled = local.config.context.lacework.aws_audit_config.bucket_logs_enabled
  bucket_enable_mfa_delete = local.config.context.lacework.aws_audit_config.bucket_enable_mfa_delete
  bucket_versioning_enabled = local.config.context.lacework.aws_audit_config.bucket_versioning_enabled
  bucket_force_destroy = local.config.context.lacework.aws_audit_config.bucket_force_destroy
  bucket_sse_algorithm = local.config.context.lacework.aws_audit_config.bucket_sse_algorithm
  bucket_sse_key_arn = local.config.context.lacework.aws_audit_config.bucket_sse_key_arn
  log_bucket_name = local.config.context.lacework.aws_audit_config.log_bucket_name
  access_log_prefix = local.config.context.lacework.aws_audit_config.access_log_prefix
  s3_notification_log_prefix = local.config.context.lacework.aws_audit_config.s3_notification_log_prefix
  s3_notification_type = local.config.context.lacework.aws_audit_config.s3_notification_type
  sns_topic_arn = local.config.context.lacework.aws_audit_config.sns_topic_arn
  sns_topic_name = local.config.context.lacework.aws_audit_config.sns_topic_name
  sns_topic_encryption_key_arn = local.config.context.lacework.aws_audit_config.sns_topic_encryption_key_arn
  sns_topic_encryption_enabled = local.config.context.lacework.aws_audit_config.sns_topic_encryption_enabled
  sqs_queue_name = local.config.context.lacework.aws_audit_config.sqs_queue_name
  sqs_encryption_enabled = local.config.context.lacework.aws_audit_config.sqs_encryption_enabled
  sqs_encryption_key_arn = local.config.context.lacework.aws_audit_config.sqs_encryption_key_arn
  use_s3_bucket_notification = local.config.context.lacework.aws_audit_config.use_s3_bucket_notification
  use_existing_access_log_bucket = local.config.context.lacework.aws_audit_config.use_existing_access_log_bucket
  use_existing_sns_topic = local.config.context.lacework.aws_audit_config.use_existing_sns_topic
  cross_account_policy_name = local.config.context.lacework.aws_audit_config.cross_account_policy_name
  sqs_queues = local.config.context.lacework.aws_audit_config.sqs_queues
  lacework_integration_name = local.config.context.lacework.aws_audit_config.lacework_integration_name
  lacework_aws_account_id = local.config.context.lacework.aws_audit_config.lacework_aws_account_id
  wait_time = local.config.context.lacework.aws_audit_config.wait_time
  kms_key_rotation = local.config.context.lacework.aws_audit_config.kms_key_rotation
  kms_key_deletion_days = local.config.context.lacework.aws_audit_config.kms_key_deletion_days
  kms_key_multi_region = local.config.context.lacework.aws_audit_config.kms_key_multi_region
  enable_cloudtrail_s3_management_events = local.config.context.lacework.aws_audit_config.enable_cloudtrail_s3_management_events

  tags                       = merge(
    {
      environment = local.config.context.global.environment
      deployment = local.config.context.global.deployment
    }, 
    local.config.context.lacework.aws_audit_config.tags
  )
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
      enable_swap                     = lookup(ec2, "enable_swap", true)
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

  deploy_calico = local.config.context.aws.eks.deploy_calico
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
# EKS AUTOSCALER
#################################################


# eks-autoscale
module "eks-autoscaler" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/eks-autoscale"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.aws.region
  
  cluster_name = module.eks[0].cluster_name
  cluster_oidc_issuer = module.eks[0].cluster.identity[0].oidc[0].issuer

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks
  ]
}

module "eks-windows-configmap" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks-windows.enabled == true ) ? 1 : 0
  source       = "./modules/eks-windows-configmap"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment

  cluster_name = module.eks-windows[0].cluster.id
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
    module.eks
  ]
}

##################################################
# AWS EKS Calico
##################################################

module "eks-calico" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.aws.eks.deploy_calico == true) ? 1 : 0
  source                                = "./modules/eks-calico"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  cluster_name                          = module.eks[0].cluster.id
  region                                = local.config.context.aws.region

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
   
    module.eks-autoscaler
  ]
}

##################################################
# AWS EKS Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "lacework-daemonset" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/kubernetes/daemonset"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  cluster_name                          = module.eks[0].cluster.id
  
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
   
    module.eks-autoscaler
  ]
}

# lacework daemonset and kubernetes compliance
module "lacework-daemonset-windows" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks-windows.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset-windows.enabled == true  ) ? 1 : 0
  source                                = "./modules/kubernetes/daemonset-windows"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  cluster_name                          = module.eks[0].cluster.id
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
   
    module.eks-autoscaler
  ]
}

# lacework kubernetes admission controller
module "lacework-admission-controller" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/kubernetes/admission-controller"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  cluster_name                          = module.eks[0].cluster.id
  
  lacework_account_name = local.config.context.lacework.account_name
  lacework_proxy_token  = local.config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
   
    module.eks-autoscaler
  ]
}

# lacework eks audit
module "lacework-eks-audit" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.eks.enabled == true && local.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true  ) ? 1 : 0
  source      = "./modules/eks-audit"
  region                                = local.config.context.aws.region
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  cluster_name                          = "${local.config.context.aws.eks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.eks-windows,
    module.eks,
   
    module.eks-autoscaler
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

  syscall_config = var.default_lacework_sysconfig_path
}

module "ssm-deploy-lacework-code-aware-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_lacework_code_aware_agent == true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-code-aware-agent"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy aws cli
module "ssm-deploy-aws-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_aws_cli== true ) ? 1 : 0
  source       = "./modules/ssm/deploy-aws-cli"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy lacework cli
module "ssm-deploy-lacework-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_lacework_cli== true ) ? 1 : 0
  source       = "./modules/ssm/deploy-lacework-cli"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy kubectl cli
module "ssm-deploy-kubectl-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_kubectl_cli== true ) ? 1 : 0
  source       = "./modules/ssm/deploy-kubectl-cli"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# ssm deploy protonvpn docker
module "ssm-deploy-protonvpn-docker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.ssm.deploy_protonvpn_docker== true ) ? 1 : 0
  source       = "./modules/ssm/deploy-protonvpn-docker"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  protonvpn_user = var.default_protonvpn_user
  protonvpn_password = var.default_protonvpn_password
  protonvpn_tier = var.default_protonvpn_tier
  protonvpn_server = var.default_protonvpn_server
  protonvpn_protocol = var.default_protonvpn_protocol
}

##################################################
# AWS RDS
##################################################

module "rds" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.ssm.enabled == true && local.config.context.aws.rds.enabled == true ) ? 1 : 0
  source = "./modules/rds"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  region                        = local.config.context.aws.region
  
  igw_id                        = module.ec2[0].public_app_igw.id
  vpc_id                        = module.ec2[0].public_app_vpc.id
  vpc_subnet                    = module.ec2[0].public_app_network
  ec2_instance_role_name        = module.ec2[0].ec2_instance_app_role.name
  user_role_name                = local.config.context.aws.rds.user_role_name
  instance_type                 = local.config.context.aws.rds.instance_type
  trusted_sg_id                 = module.ec2[0].public_app_sg.id

  depends_on = [
    module.ec2
  ]
}