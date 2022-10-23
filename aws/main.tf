module "environment-proservlab" {
  source      = "./modules/environment"
  environment = "proservlab"
  region      = var.region

  # slack
  enable_slack_alerts = true
  slack_token         = var.slack_token

  # jira
  enable_jira_cloud_alerts = true
  jira_cloud_url           = var.jira_cloud_url
  jira_cloud_project_key   = var.jira_cloud_project_key
  jira_cloud_issue_type    = var.jira_cloud_issue_type
  jira_cloud_api_token     = var.jira_cloud_api_token
  jira_cloud_username      = var.jira_cloud_username

  # eks cluster
  cluster_name = var.cluster_name

  # aws core environment
  enable_ec2     = true
  enable_eks     = true
  enable_eks_app = true
  enable_eks_psp = false

  instances = [
    {
      name             = "ec2-private-1"
      public           = false
      instance_type    = "t2.micro"
      ami_name         = "ubuntu_focal"
      enable_ssm       = true
      ssm_deploy_tag   = { ssm_deploy_lacework = "true" }
      tags             = {}
      user_data        = null
      user_data_base64 = null
    },
    {
      name             = "ec2-public-1"
      public           = true
      instance_type    = "t2.micro"
      ami_name         = "ubuntu_focal"
      enable_ssm       = true
      ssm_deploy_tag   = { ssm_deploy_lacework = "true" }
      tags             = {}
      user_data        = null
      user_data_base64 = null
    },
    {
      name             = "ec2-public-2"
      public           = true
      instance_type    = "t2.micro"
      ami_name         = "ubuntu_focal"
      enable_ssm       = true
      ssm_deploy_tag   = { ssm_deploy_lacework = "false" }
      tags             = {}
      user_data        = null
      user_data_base64 = null
    }
  ]

  # kubernetes admission controller
  proxy_token = var.proxy_token

  # lacework
  lacework_agent_access_token           = var.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  lacework_account_name                 = var.lacework_account_name
  enable_lacework_alerts                = true
  enable_lacework_audit_config          = true
  enable_lacework_custom_policy         = true
  enable_lacework_daemonset             = true
  enable_lacework_daemonset_compliance  = true
  enable_lacework_agentless             = true
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

