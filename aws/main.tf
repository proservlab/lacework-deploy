module "environment-proservlab" {
  source      = "./modules/environment"
  environment = "proservlab"
  region      = var.region

  # slack
  slack_token = var.slack_token

  # eks cluster
  cluster_name = var.cluster_name

  # aws core environment
  enable_ec2     = true
  enable_eks     = true
  enable_eks_app = true

  # kubernetes admission controller
  proxy_token = var.proxy_token

  # lacework
  lacework_agent_access_token           = var.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  lacework_account_name                 = var.lacework_account_name
  enable_lacework_alerts                = false
  enable_lacework_audit_config          = true
  enable_lacework_custom_policy         = true
  enable_lacework_daemonset             = true
  enable_lacework_agentless             = false
  enable_lacework_ssm_deployment        = true
  enable_lacework_admissions_controller = true

  # attack
  enable_attack_kubernetes_voteapp = true

  providers = {
    aws        = aws.main
    lacework   = lacework.main
    kubernetes = kubernetes.main
    helm       = helm.main
  }
}

# module "environment-proservlab-test" {
#   source      = "./modules/environment"
#   environment = "dev-test"
#   providers = {
#     aws      = aws.dev-test
#     lacework = lacework.proservlab
#   }
# }

# module "environment-proservlab-stage" {
#   source      = "./modules/environment"
#   environment = "dev-stage"
#   providers = {
#     aws      = aws.dev-stage
#     lacework = lacework.proservlab
#   }
# }

# module "environment-proservlab-prod" {
#   source      = "./modules/environment"
#   environment = "dev-prod"
#   providers = {
#     aws      = aws.dev-prod
#     lacework = lacework.proservlab
#   }
# }

# module "control_tower_integration_setup" {
#   source  = "lacework/cloudtrail-controltower/aws"
#   version = "~> 0.3.0"
#   providers = {
#     aws.audit       = aws.audit
#     aws.log_archive = aws.log
#     lacework        = lacework.proservlab

#     # organization provider when lacework subaccounts are being used
#     # lacework        = lacework.proservlab-organization
#   }
#   # SNS Topic ARN is usually in the form: arn:aws:sns:<control_tower_region>:<aws_audit_account_id>:aws-controltower-AllConfigNotifications
#   sns_topic_arn = "arn:aws:sns:us-east-1:986224395668:aws-controltower-AllConfigNotifications"
#   # S3 Bucket ARN is usually in the form: arn:aws:s3:::aws-controltower-logs-<log_archive_account_id>-<control_tower_region>
#   s3_bucket_arn = "arn:aws:s3:::aws-controltower-logs-538045531862-us-east-1"

#   # organization mapping
#   # org_account_mappings = [{
#   #   default_lacework_account = "proservlab"

#   #   mapping = [
#   #     {
#   #       lacework_account = "proservlab-prod"
#   #       aws_accounts     = ["837437350477"]
#   #     },
#   #     {
#   #       lacework_account = "proservlab-stage"
#   #       aws_accounts     = ["466038157367"]
#   #     },
#   #     {
#   #       lacework_account = "proservlab-test"
#   #       aws_accounts     = ["997124715511"]
#   #     }
#   #   ]
#   # }]
# }