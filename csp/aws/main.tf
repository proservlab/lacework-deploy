#########################
# DEFAULTS
#
# ssm_default_tags - all ssm deployment tags set
#                    to false
#########################

module "defaults" {
  source = "./modules/defaults"
}

#########################
# LOCALS
#
# instances - a list of all instances to create
#             including ssm tag overrides
#########################

locals {
  instances = [
    {
      name           = "ec2-private-1"
      public         = false
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "true" }
      # override default ssm action tags
      tags             = merge(module.defaults.ssm_default_tags, {})
      user_data        = null
      user_data_base64 = null
    },
    {
      name           = "ec2-public-1"
      public         = true
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "true" }
      # override default ssm action tags
      tags = merge(module.defaults.ssm_default_tags, {
        ssm_deploy_docker               = "true"
        ssm_exec_docker_cpuminer        = "true"
        ssm_exec_http_listener_attacker = "true"
        ssm_connect_enumerate_host      = "true"
      })
      user_data        = null
      user_data_base64 = null
    },
    {
      name           = "ec2-public-2"
      public         = true
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "true" }
      # override default ssm action tags
      tags = merge(module.defaults.ssm_default_tags, {
        ssm_connect_oast_host         = "true"
        ssm_deploy_malware_eicar      = "true"
        ssm_deploy_secret_ssh_private = "true"
        ssm_exec_reverse_shell_target = "true"
        ssm_deploy_inspector_agent    = "true"
        ssm_deploy_git                = "true"
        ssm_exec_git_codecov          = "true"
      })

      user_data        = <<-EOT
                          #!/bin/bash

                          /usr/bin/touch /tmp/deployed
                          EOT
      user_data_base64 = null
    },

    {
      name           = "ec2-public-3"
      public         = true
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "true" }
      # override default ssm action tags
      tags = merge(module.defaults.ssm_default_tags, {
        ssm_deploy_docker                  = "true"
        ssm_deploy_secret_ssh_public       = "true"
        ssm_exec_reverse_shell_attacker    = "true"
        ssm_exec_docker_log4shell_attacker = "true"
      })
      user_data        = null
      user_data_base64 = null
    },
    {
      name           = "ec2-public-4"
      public         = true
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "true" }
      # override default ssm action tags
      tags = merge(module.defaults.ssm_default_tags, {
        ssm_deploy_docker                = "true"
        ssm_exec_docker_log4shell_target = "true"
        ssm_connect_bad_ip               = "true"
      })
      user_data        = null
      user_data_base64 = null
    }
  ]
}

#########################
# ATTACKER ENVIRONMENT
#
# deploys attacker environment
#########################

# TDB - currently all attack run within local network

#########################
# TARGET ENVIRONMENT
#
# deploys target environment with lacework components installed
#########################

module "environment-proservlab" {
  source      = "./modules/environment"
  environment = "proservlab"
  region      = var.region

  # override enable
  disable_all = false
  enable_all  = false

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

  # aws ssm document setup - provides optional install capability
  enable_inspector     = true
  enable_deploy_git    = true
  enable_deploy_docker = true

  # ec2 instance definitions
  instances = local.instances

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
  enable_lacework_eks_audit             = false

  # vulnerable apps
  enable_attack_kubernetes_voteapp           = true
  enable_attack_kubernetes_log4shell         = true
  enable_attack_kubernetes_privileged_pod    = true
  enable_attack_kubernetes_root_mount_fs_pod = false

  # attack surface
  enable_attacksurface_agentless_secrets = true

  # attacker
  enable_attacker_malware_eicar          = true
  enable_attacker_connect_badip          = true
  enable_attacker_connect_enumerate_host = true
  enable_attacker_connect_oast_host      = true
  enable_attacker_exec_codecov           = true
  enable_attacker_exec_reverseshell      = true
  enable_attacker_exec_http_listener     = true
  attacker_exec_reverseshell_port        = 4445
  attacker_exec_http_port                = 8080
  attacker_exec_reverseshell_payload     = <<-EOT
                                            touch /tmp/target_pwned
                                            EOT
  enable_attacker_exec_docker_cpuminer   = true
  enable_attacker_exec_docker_log4shell  = true
  enable_attacker_kubernetes_app_kali    = false

  providers = {
    aws        = aws.main
    lacework   = lacework.main
    kubernetes = kubernetes.main
    helm       = helm.main
  }
}

