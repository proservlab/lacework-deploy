locals {
    ssm_default_tags = {
        ssm_connect_bad_ip              = "false"
        ssm_connect_enumerate_host      = "false"
        ssm_connect_oast_host           = "false"
        ssm_deploy_malware_eicar        = "false"
        ssm_deploy_secret_ssh_public    = "false"
        ssm_deploy_secret_ssh_private   = "false"
        ssm_exec_reverse_shell_attacker = "false"
        ssm_exec_reverse_shell_target   = "false"
        ssm_exec_git_codecov_target     = "false"
        ssm_exec_http_listener_attacker = "false"
        ssm_exec_docker_cpuminer        = "false"
        ssm_exec_docker_log4shell_target = "false"
        ssm_exec_docker_log4shell_attacker = "false"
        ssm_deploy_inspector_agent      = "false"
        ssm_deploy_docker               = "false"
        ssm_deploy_git                  = "false"
        ssm_exec_port_forward_target    = "false"
        ssm_exec_port_forward_attacker  = "false"
        ssm_exec_docker_compromised_keys_attacker = "false"
  }

  environment_defaults = {
    environment = null
    region      = null

    # override enable
    disable_all = false
    enable_all  = false

    # slack
    enable_slack_alerts = false
    slack_token         = null

    # jira
    enable_jira_cloud_alerts = false
    jira_cloud_url           = null
    jira_cloud_project_key   = null
    jira_cloud_issue_type    = null
    jira_cloud_api_token     = null
    jira_cloud_username      = null

    # eks cluster
    cluster_name = null

    # aws core environment
    enable_ec2     = false
    enable_eks     = false
    enable_eks_app = false
    enable_eks_psp = false

    # aws ssm document setup - provides optional install capability
    enable_inspector     = false
    enable_deploy_git    = false
    enable_deploy_docker = false

    # ec2 instance definitions
    instances = []

    # kubernetes admission controller
    lacework_proxy_token = null

    # lacework
    lacework_agent_access_token           = null
    lacework_server_url                   = null
    lacework_account_name                 = null
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

    # attack surface
    enable_target_attacksurface_secrets_ssh = false

    # simulation
    enable_target_malware_eicar          = false
    enable_target_connect_badip          = false
    enable_target_connect_enumerate_host = false
    enable_target_connect_oast_host      = false
    enable_target_codecov           = false
    enable_attacker_reverseshell      = false
    enable_attacker_http_listener     = false
    enable_attacker_port_forward      = false
    attacker_reverseshell_port        = 4445
    attacker_http_port                = 8080
    attacker_reverseshell_payload     = <<-EOT
                                              touch /tmp/target_pwned
                                              EOT
    enable_target_docker_cpuminer   = false
    enable_target_port_forward       = false
    enable_attacker_docker_log4shell  = false
    enable_target_kubernetes_app_kali    = false
    enable_attacker_compromised_credentials = false
  }
}