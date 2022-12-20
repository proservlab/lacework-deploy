#########################
# AWS COMPUTE
#########################

# ec2
module "ec2-instances" {
  count = ((var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.enabled == true && length(var.config.context.aws.ec2.instances) > 0 )) == true ? 1 : 0
  source       = "./modules/aws/ec2/instances"
  environment  = var.config.context.global.environment

  # list of instances to configure
  instances = var.config.context.aws.ec2.instances

  # allow endpoints inside their own security group to communicate
  trust_security_group = var.config.context.global.trust_security_group

  public_ingress_rules = var.config.context.aws.ec2.public_ingress_rules
  public_egress_rules = var.config.context.aws.ec2.public_egress_rules
  private_ingress_rules = var.config.context.aws.ec2.private_ingress_rules
  private_egress_rules = var.config.context.aws.ec2.private_egress_rules

  public_network = var.config.context.aws.ec2.public_network
  public_subnet = var.config.context.aws.ec2.public_subnet
  private_network = var.config.context.aws.ec2.private_network
  private_subnet = var.config.context.aws.ec2.private_subnet
  private_nat_subnet = var.config.context.aws.ec2.private_nat_subnet
}

# eks
module "eks" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.eks.enabled == true ) ? 1 : 0
  source       = "./modules/aws/eks"
  environment  = var.config.context.global.environment
  cluster_name = var.config.context.aws.eks.cluster_name
  region       = var.config.context.aws.region
  aws_profile_name = var.config.context.aws.profile_name
}

#########################
# AWS INSPECTOR
#########################

# inspector
module "inspector" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.inspector.enabled == true ) ? 1 : 0
  source       = "./modules/aws/inspector"
  environment  = var.config.context.global.environment
}

#########################
# SSM 
#########################

# ssm deploy inspector agent
module "ssm-deploy-inspector-agent" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.deploy_inspector_agent == true && var.config.context.aws.inspector.enabled == true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-inspector-agent"
  environment  = var.config.context.global.environment
}

# ssm deploy git
module "ssm-deploy-git" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.deploy_git== true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-git"
  environment  = var.config.context.global.environment
}

# ssm deploy docker
module "ssm-deploy-docker" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.deploy_docker== true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-docker"
  environment  = var.config.context.global.environment
}

# ssm deploy lacework agent
module "ssm-deploy-lacework-agent" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.deploy_lacework_agent == true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-lacework-agent"
  environment  = var.config.context.global.environment
  lacework_agent_access_token = var.config.context.lacework.agent.token
  lacework_server_url         = var.config.context.lacework.server_url
}

# ssm deploy lacework syscall_config.yaml
module "lacework-ssm-deployment-syscall-config" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.deploy_lacework_syscall_config == true ) ? 1 : 0
  source       = "./modules/aws/ssm/deploy-lacework-syscall-config"
  environment  = var.config.context.global.environment
  syscall_config =  <<-EOT
                    etype.file:
                        send-if-matches:
                            file_mod_passwd:
                                watchpath: /etc/passwd
                        send-if-matches:
                            file_mod_ssh_user_config:
                                watchpath: /home/*/.ssh/
                        send-if-matches:
                            file_mod_root_ssh_user_config:
                                watchpath: /root/.ssh/
                        send-if-matches:
                            file_mod_root_crond:
                                watchpath: /etc/cron.d/root
                        send-if-matches:
                            file_mod_root_crond:
                                watchpath: /var/spool/cron/root
                    EOT
}

#########################
# KUBERNETES 
#########################

module "kubernetes-app" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.eks.enabled == true && var.config.context.aws.eks.deploy_app == true ) ? 1 : 0
  source      = "./modules/kubernetes/app"
  environment = var.config.context.global.environment

  depends_on = [
    module.eks
  ]
}

module "kubenetes-psp" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.eks.enabled == true && var.config.context.aws.eks.deploy_psp == true ) ? 1 : 0
  source      = "./modules/kubernetes/psp"
  environment = var.config.context.global.environment

  depends_on = [
    module.eks
  ]
}

#########################
# Lacework
#########################

# lacework cloud audit and config collection
module "lacework-audit-config" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.lacework.audit_config == true ) ? 1 : 0
  source      = "./modules/lacework/audit-config"
  environment = var.config.context.global.environment
}

# lacework agentless scanning
module "lacework-agentless" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.lacework.agentless.enabled == true ) ? 1 : 0
  source      = "./modules/lacework/agentless"
  environment = var.config.context.global.environment
}

# lacework alerts
module "lacework-alerts" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.lacework.alerts.enabled == true ) ? 1 : 0
  source       = "./modules/lacework/alerts"
  environment  = var.config.context.global.environment
  
  enable_slack_alerts       = var.config.context.lacework.alerts.slack.enabled
  slack_token               = var.config.context.lacework.alerts.slack.api_token

  enable_jira_cloud_alerts  = var.config.context.lacework.alerts.jira.enabled
  jira_cloud_url            = var.config.context.lacework.alerts.jira.cloud_url
  jira_cloud_project_key    = var.config.context.lacework.alerts.jira.cloud_project_key
  jira_cloud_api_token      = var.config.context.lacework.alerts.jira.cloud_api_token
  jira_cloud_issue_type     = var.config.context.lacework.alerts.jira.cloud_issue_type
  jira_cloud_username       = var.config.context.lacework.alerts.jira.cloud_username
}

# lacework custom policy
module "lacework-custom-policy" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.lacework.custom_policy == true ) ? 1 : 0
  source       = "./modules/lacework/custom-policy"
  environment  = var.config.context.global.environment
}

# lacework kubernetes namespace
resource "kubernetes_namespace" "lacework" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.eks.enabled == true && (var.config.context.lacework.agent.kubernetes.admission_controller.enabled == true || var.config.context.lacework.agent.kubernetes.daemonset.enabled == true || var.config.context.lacework.agent.kubernetes.eks_audit_logs.enabled == true ) ) ? 1 : 0
  metadata {
    name = "lacework"
  }

  depends_on = [
    module.eks
  ]
}

# lacework daemonset and kubernetes compliance
module "lacework-daemonset" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.eks.enabled == true && var.config.context.lacework.agent.kubernetes.daemonset.enabled == true ) ? 1 : 0
  source                                = "./modules/lacework/daemonset"
  cluster_name                          = var.config.context.aws.eks.cluster_name
  environment                           = var.config.context.global.environment
  lacework_agent_access_token           = var.config.context.lacework.agent.token
  lacework_server_url                   = var.config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = var.config.context.lacework.agent.kubernetes.compliance.enabled
  lacework_cluster_agent_cluster_region = var.config.context.aws.region

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

# lacework kubernetes admission controller
module "lacework-admission-controller" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.eks.enabled == true && var.config.context.lacework.agent.kubernetes.admission_controller.enabled == true ) ? 1 : 0
  source       = "./modules/lacework/admission-controller"
  environment  = var.config.context.global.environment
  lacework_account_name = var.config.context.lacework.account_name
  lacework_proxy_token = var.config.context.lacework.agent.kubernetes.proxy_scanner.token

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

# lacework eks audit
module "lacework-eks-audit" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.eks.enabled == true && var.config.context.lacework.agent.kubernetes.eks_audit_logs == true ) ? 1 : 0
  source      = "./modules/lacework/eks-audit"
  region      = var.config.context.aws.region
  environment = var.config.context.global.environment
  cluster_names = [var.config.context.aws.eks.cluster_name]

  depends_on = [
    module.eks,
    kubernetes_namespace.lacework
  ]
}

data "aws_instances" "cluster" {
  instance_tags = {
    "eks:cluster-name" = var.config.context.aws.eks.cluster_name
  }

  instance_state_names = ["running"]

  depends_on = [
    module.eks
  ]
}





