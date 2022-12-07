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
  target = {
    reverseshell = length(module.target.ec2-instances) > 0 ? flatten([
      for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_reverse_shell_target == "true"
    ]) : []
    log4shell = length(module.target.ec2-instances) > 0 ? flatten([
      for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_docker_log4shell_target == "true"
    ]) : []
    codecov = length(module.target.ec2-instances) > 0 ? flatten([
      for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_git_codecov_target == "true"
    ]) : []
    port_forward = length(module.target.ec2-instances) > 0 ? flatten([
      for instance in module.target.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_port_forward_target == "true"
    ]) : []
  }

  attacker = {
    http_listener = length(module.attacker.ec2-instances) > 0 ? flatten([
      for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_http_listener_attacker == "true"
    ]) : []
    reverseshell = length(module.attacker.ec2-instances) > 0 ? flatten([
      for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_reverse_shell_attacker == "true"
    ]) : []
    log4shell = length(module.attacker.ec2-instances) > 0 ? flatten([
      for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_docker_log4shell_attacker == "true"
    ]) : []
    port_forward = length(module.attacker.ec2-instances) > 0 ? flatten([
      for instance in module.attacker.ec2-instances[0].instances : instance.instance if instance.instance.tags.ssm_exec_port_forward_attacker == "true"
    ]) : []
  }

  attacker_instances = [
    {
      name           = "attacker-public-1"
      public         = true
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "false" }
      # override default ssm action tags
      tags = merge(module.defaults.ssm_default_tags, {
        ssm_deploy_docker               = "true"
        ssm_exec_reverse_shell_attacker = "true"
      })
      user_data        = null
      user_data_base64 = null
    },
    {
      name           = "attacker-public-2"
      public         = true
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "false" }
      # override default ssm action tags
      tags = merge(module.defaults.ssm_default_tags, {
        ssm_deploy_docker                         = "true"
        ssm_exec_docker_compromised_keys_attacker = "true"
      })
      user_data        = null
      user_data_base64 = null
    },
  ]

  target_instances = [
    {
      name           = "target-public-1"
      public         = true
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "true" }
      # override default ssm action tags
      tags = merge(module.defaults.ssm_default_tags, {
        ssm_deploy_docker             = "true"
        ssm_deploy_git                = "true"
        ssm_deploy_secret_ssh_private = "true"
        ssm_exec_reverse_shell_target = "true"
        ssm_deploy_inspector_agent    = "true"
      })

      user_data        = null
      user_data_base64 = null
    },
    {
      name           = "target-public-2"
      public         = true
      instance_type  = "t2.micro"
      ami_name       = "ubuntu_focal"
      enable_ssm     = true
      ssm_deploy_tag = { ssm_deploy_lacework = "true" }
      # override default ssm action tags
      tags = merge(module.defaults.ssm_default_tags, {
        ssm_deploy_secret_ssh_public = "true"
      })
      user_data        = null
      user_data_base64 = null
    },
  ]

  target_iam_policies = {
    "simulation_power_user" = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "AllowSpecifics",
          "Action" : [
            "lambda:*",
            "apigateway:*",
            "ec2:*",
            "rds:*",
            "s3:*",
            "sns:*",
            "states:*",
            "ssm:*",
            "sqs:*",
            "iam:*",
            "elasticloadbalancing:*",
            "autoscaling:*",
            "cloudwatch:*",
            "cloudfront:*",
            "route53:*",
            "ecr:*",
            "logs:*",
            "ecs:*",
            "application-autoscaling:*",
            "logs:*",
            "events:*",
            "elasticache:*",
            "es:*",
            "kms:*",
            "dynamodb:*",
            "fms:*",
            "guardduty:*",
            "inspector:*",
            "waf:*"
          ],
          "Effect" : "Allow",
          "Resource" : "*"
        },
        {
          "Sid" : "DenySpecifics",
          "Action" : [
            "iam:*User*",
            "iam:*Login*",
            "iam:*Group*",
            "iam:*Provider*",
            "aws-portal:*",
            "budgets:*",
            "config:*",
            "directconnect:*",
            "aws-marketplace:*",
            "aws-marketplace-management:*",
            "ec2:*ReservedInstances*"
          ],
          "Effect" : "Deny",
          "Resource" : "*"
        }
      ]
    })
  }

  target_iam_users = [
    {
      name   = "claude.kripto@interlacelabs"
      policy = local.target_iam_policies["simulation_power_user"]
    },
    {
      name   = "dee.fensivason@interlacelabs"
      policy = local.target_iam_policies["simulation_power_user"]
    },
    {
      name   = "haust.kripto@interlacelabs"
      policy = local.target_iam_policies["simulation_power_user"]
    },
    {
      name   = "kees.kompromize@interlacelabs"
      policy = local.target_iam_policies["simulation_power_user"]
    },
    {
      name   = "rand.sumwer@interlacelabs"
      policy = local.target_iam_policies["simulation_power_user"]
    },
  ]

  target_log4shell_http_port = 8000
  target_port_forward_ports = flatten([
    for attacker in local.attacker.port_forward : [
      {
        src_port    = 1389
        dst_ip      = local.attacker.port_forward[0].private_ip
        dst_port    = 1389
        description = "log4shell target port forward"
      },
      {
        src_port    = 8080
        dst_ip      = local.attacker.port_forward[0].private_ip
        dst_port    = 8080
        description = "log4shell target port forward"
      }
    ]
  ])

  attacker_log4shell_ldap_port        = 1389
  attacker_log4shell_http_port        = 8080
  attacker_reverseshell_port          = 4444
  attacker_generic_http_listener_port = 8444
  attacker_port_forward_server_port   = 8888

  ssh_port = 22
}

#########################
# ATTACKER ENVIRONMENT
#
# deploys attacker environment
#########################

module "attacker" {
  source      = "./modules/environment"
  environment = "attacker"
  region      = var.region

  # override enable
  disable_all = false
  enable_all  = false

  # slack
  enable_slack_alerts = false
  slack_token         = var.slack_token

  # jira
  enable_jira_cloud_alerts = false
  jira_cloud_url           = var.jira_cloud_url
  jira_cloud_project_key   = var.jira_cloud_project_key
  jira_cloud_issue_type    = var.jira_cloud_issue_type
  jira_cloud_api_token     = var.jira_cloud_api_token
  jira_cloud_username      = var.jira_cloud_username

  # eks cluster
  cluster_name = "attacker-cluster"

  # aws core environment
  enable_ec2     = true
  enable_eks     = false
  enable_eks_app = false
  enable_eks_psp = false

  public_network     = "172.18.0.0/16"
  public_subnet      = "172.18.0.0/24"
  private_network    = "172.19.0.0/16"
  private_subnet     = "172.19.100.0/24"
  private_nat_subnet = "172.19.10.0/24"

  # aws ssm document setup - provides optional install capability
  enable_inspector     = true
  enable_deploy_git    = true
  enable_deploy_docker = true

  # ec2 instance definitions
  instances = local.attacker_instances
  public_ingress_rules = [
    {
      from_port   = local.ssh_port
      to_port     = local.ssh_port
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "allow ssh inbound"
    },
  ]
  private_ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "allow ssh inbound"
    }
  ]

  # lacework
  lacework_proxy_token                  = var.lacework_proxy_token
  lacework_agent_access_token           = var.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  lacework_account_name                 = var.lacework_account_name
  enable_lacework_alerts                = false
  enable_lacework_audit_config          = false
  enable_lacework_custom_policy         = false
  enable_lacework_daemonset             = false
  enable_lacework_daemonset_compliance  = false
  enable_lacework_agentless             = false
  enable_lacework_ssm_deployment        = false
  enable_lacework_admissions_controller = false
  enable_lacework_eks_audit             = false

  # vulnerable apps
  enable_attack_kubernetes_voteapp           = false
  enable_attack_kubernetes_log4shell         = false
  enable_attack_kubernetes_privileged_pod    = false
  enable_attack_kubernetes_root_mount_fs_pod = false
  providers = {
    aws        = aws.attacker
    lacework   = lacework.attacker
    kubernetes = kubernetes.attacker
    helm       = helm.attacker
  }
}

#########################
# TARGET ENVIRONMENT
#
# deploys target environment with lacework components installed
#########################

module "target" {
  source      = "./modules/environment"
  environment = "target"
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
  cluster_name = "target-cluster"

  # aws core environment
  enable_ec2     = true
  enable_eks     = false
  enable_eks_app = false
  enable_eks_psp = false

  public_network     = "172.17.0.0/16"
  public_subnet      = "172.17.0.0/24"
  private_network    = "172.16.0.0/16"
  private_subnet     = "172.16.100.0/24"
  private_nat_subnet = "172.16.10.0/24"

  # aws ssm document setup - provides optional install capability
  enable_inspector     = true
  enable_deploy_git    = true
  enable_deploy_docker = true

  # ec2 instance definitions
  instances = local.target_instances
  public_ingress_rules = [
    {
      from_port   = local.ssh_port
      to_port     = local.ssh_port
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "allow ssh inbound"
    },
  ]
  private_ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      description = "allow ssh inbound"
    }
  ]

  # kubernetes admission controller
  lacework_proxy_token = var.lacework_proxy_token

  # lacework
  lacework_agent_access_token           = var.lacework_agent_access_token
  lacework_server_url                   = var.lacework_server_url
  lacework_account_name                 = var.lacework_account_name
  enable_lacework_alerts                = true
  enable_lacework_audit_config          = true
  enable_lacework_custom_policy         = true
  enable_lacework_daemonset             = false
  enable_lacework_daemonset_compliance  = false
  enable_lacework_agentless             = true
  enable_lacework_ssm_deployment        = true
  enable_lacework_admissions_controller = false
  enable_lacework_eks_audit             = false

  # vulnerable apps
  enable_attack_kubernetes_voteapp           = false
  enable_attack_kubernetes_log4shell         = false
  enable_attack_kubernetes_privileged_pod    = false
  enable_attack_kubernetes_root_mount_fs_pod = false

  providers = {
    aws        = aws.target
    lacework   = lacework.target
    kubernetes = kubernetes.target
    helm       = helm.target
  }
}

#########################
# SIMULATION
#
# after infrastructure deployment to attacker and
# target, use the instance details as parameters
# for attacker and target simulations.
#########################

# simulation for target environment
locals {
  target_public_sg_ingress = concat(
    [
      for instance in local.attacker.log4shell : {
        from_port   = local.target_log4shell_http_port
        to_port     = local.target_log4shell_http_port
        protocol    = "tcp"
        cidr_block  = "${instance.public_ip}/32"
        description = "allow log4shell inbound"
      }
    ],
  )
}

resource "aws_security_group_rule" "simulation-target-public-ingress" {
  count = length(local.target_public_sg_ingress)

  type              = "ingress"
  from_port         = local.target_public_sg_ingress[count.index].from_port
  to_port           = local.target_public_sg_ingress[count.index].to_port
  protocol          = local.target_public_sg_ingress[count.index].protocol
  cidr_blocks       = [local.target_public_sg_ingress[count.index].cidr_block]
  description       = local.target_public_sg_ingress[count.index].description
  security_group_id = module.target.public_sg.id

  provider = aws.target
}

# brute force some users - this should be assume role at some point
resource "aws_iam_user" "target_iam_users" {
  for_each = { for i in local.target_iam_users : i.name => i }
  name     = each.key

  provider = aws.target
}

resource "aws_iam_user_policy" "target_iam_users_policy" {
  for_each = { for i in local.target_iam_users : i.name => i }
  name     = "iam-policy-${each.value.name}"
  user     = each.key
  policy   = each.value.policy

  provider = aws.target

  depends_on = [
    aws_iam_user.target_iam_users
  ]
}

resource "aws_iam_access_key" "target_iam_users_access_key" {
  for_each = { for i in local.target_iam_users : i.name => i }
  user     = each.key

  depends_on = [
    aws_iam_user.target_iam_users
  ]

  provider = aws.target
}

data "template_file" "compromised_keys" {
  for_each = { for i in local.target_iam_users : i.name => i }
  template = <<-EOT
    AWS_ACCESS_KEY_ID=${aws_iam_access_key.target_iam_users_access_key[each.key].id}
    AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.target_iam_users_access_key[each.key].secret}
    AWS_DEFAULT_REGION=${var.region}
    AWS_DEFAULT_OUTPUT=json
    EOT
}

module "simulation-target" {
  source      = "./modules/environment"
  environment = "simulation-target"
  region      = var.region

  # set all endpoint target/attacker
  attacker_instance_http_listener   = local.attacker.http_listener
  attacker_instance_log4shell       = local.attacker.log4shell
  attacker_instance_reverseshell    = local.attacker.reverseshell
  attacker_instance_port_forward    = local.attacker.port_forward
  attacker_port_forward_server_port = local.attacker_port_forward_server_port
  target_instance_log4shell         = local.target.log4shell
  target_instance_reverseshell      = local.target.reverseshell
  target_instance_port_forward      = local.target.port_forward

  # in simulation cluster name is used to exec kube commands
  # for example: deploy kali instance
  cluster_name = "target-cluster"

  # simulation basic
  # -------------------
  # no attacker infrastructure required. all attacks run
  # via ssm as root. any instances tagged will have the
  # enable attacks run, every 30 minutes by default.
  enable_target_attacksurface_secrets_ssh = true
  enable_target_malware_eicar             = true
  enable_target_connect_badip             = true
  enable_target_connect_enumerate_host    = true
  enable_target_connect_oast_host         = true
  enable_target_kubernetes_app_kali       = false
  enable_target_docker_cpuminer           = true

  # simulation advanced
  # -------------------
  # attacker endpoint required. these attacks required
  # two stages. infra build then attack to ensure endpoint
  # address are available

  # log4shell
  enable_target_docker_log4shell = true
  target_log4shell_http_port     = local.target_log4shell_http_port
  attacker_log4shell_ldap_port   = local.attacker_log4shell_ldap_port
  attacker_log4shell_http_port   = local.attacker_log4shell_http_port

  # reverseshell
  enable_target_reverseshell = true
  attacker_reverseshell_port = local.attacker_reverseshell_port

  # codecov
  enable_target_codecov               = true
  attacker_generic_http_listener_port = local.attacker_generic_http_listener_port

  providers = {
    aws        = aws.target
    lacework   = lacework.target
    kubernetes = kubernetes.target
    helm       = helm.target
  }

  # port forward
  enable_target_exec_port_forward = true
  target_port_forward_ports       = local.target_port_forward_ports
}

# simulation for attacker environment
locals {
  attacker_public_sg_ingress = concat(
    [
      for instance in local.target.log4shell : {
        from_port   = local.attacker_log4shell_ldap_port
        to_port     = local.attacker_log4shell_ldap_port
        protocol    = "tcp"
        cidr_block  = "${instance.public_ip}/32"
        description = "allow log4shell ldap inbound"
      }
    ],
    [
      for instance in local.target.log4shell : {
        from_port   = local.attacker_log4shell_http_port
        to_port     = local.attacker_log4shell_http_port
        protocol    = "tcp"
        cidr_block  = "${instance.public_ip}/32"
        description = "allow log4shell http inbound"
      }
    ],
    [
      for instance in local.target.reverseshell : {
        from_port   = local.attacker_reverseshell_port
        to_port     = local.attacker_reverseshell_port
        protocol    = "tcp"
        cidr_block  = "${instance.public_ip}/32"
        description = "allow reverseshell inbound"
      }
    ],
    [
      for instance in local.target.codecov : {
        from_port   = local.attacker_generic_http_listener_port
        to_port     = local.attacker_generic_http_listener_port
        protocol    = "tcp"
        cidr_block  = "${instance.public_ip}/32"
        description = "allow codecov http inbound"
      }
    ],
    [
      for instance in local.target.port_forward : {
        from_port   = local.attacker_port_forward_server_port
        to_port     = local.attacker_port_forward_server_port
        protocol    = "tcp"
        cidr_block  = "${instance.public_ip}/32"
        description = "allow port forward server inbound"
      }
    ],
  )
}
resource "aws_security_group_rule" "simulation-attacker-public-ingress" {
  count = length(local.attacker_public_sg_ingress)

  type              = "ingress"
  from_port         = local.attacker_public_sg_ingress[count.index].from_port
  to_port           = local.attacker_public_sg_ingress[count.index].to_port
  protocol          = local.attacker_public_sg_ingress[count.index].protocol
  cidr_blocks       = [local.attacker_public_sg_ingress[count.index].cidr_block]
  description       = local.attacker_public_sg_ingress[count.index].description
  security_group_id = module.attacker.public_sg.id

  provider = aws.attacker
}

module "simulation-attacker" {
  source      = "./modules/environment"
  environment = "simulation-attacker"
  region      = var.region

  # set all endpoint target/attacker
  attacker_instance_http_listener = local.attacker.http_listener
  attacker_instance_log4shell     = local.attacker.log4shell
  attacker_instance_reverseshell  = local.attacker.reverseshell
  attacker_instance_port_forward  = local.attacker.port_forward
  target_instance_log4shell       = local.target.log4shell
  target_instance_reverseshell    = local.target.reverseshell
  target_instance_port_forward    = local.target.port_forward

  # simulation advanced
  # -------------------
  # attacker endpoint required. these attacks required
  # two stages. infra build then attack to ensure endpoint
  # address are available

  # log4shell
  enable_attacker_docker_log4shell = true
  target_log4shell_http_port       = local.target_log4shell_http_port
  attacker_log4shell_ldap_port     = local.attacker_log4shell_ldap_port
  attacker_log4shell_http_port     = local.attacker_log4shell_http_port
  attacker_log4shell_payload       = <<-EOT
                                      touch /tmp/log4shell_pwned
                                      EOT
  # reverseshell
  enable_attacker_reverseshell  = true
  attacker_reverseshell_port    = local.attacker_reverseshell_port
  attacker_reverseshell_payload = <<-EOT
                                  touch /tmp/reverseshell_pwned
                                  EOT

  # codecov
  enable_attacker_http_listener       = true
  attacker_generic_http_listener_port = local.attacker_generic_http_listener_port

  # compromised credentials
  enable_attacker_compromised_credentials = true
  attacker_compromised_credentials        = data.template_file.compromised_keys
  attacker_protonvpn_user                 = var.attacker_protonvpn_user
  attacker_protonvpn_password             = var.attacker_protonvpn_password
  attacker_protonvpn_tier                 = var.attacker_protonvpn_tier
  attacker_protonvpn_server               = var.attacker_protonvpn_server
  attacker_protonvpn_protocol             = var.attacker_protonvpn_protocol
  attacker_cloud_cryptomining_wallet      = var.attacker_cloud_cryptomining_wallet
  attacker_host_cryptomining_user         = var.attacker_host_cryptomining_user

  providers = {
    aws        = aws.attacker
    lacework   = lacework.attacker
    kubernetes = kubernetes.attacker
    helm       = helm.attacker
  }

  # port forward
  enable_attacker_exec_port_forward = true
  attacker_port_forward_server_port = local.attacker_port_forward_server_port
}