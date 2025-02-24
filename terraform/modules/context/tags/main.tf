##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../context/deployment"
}

##################################################
# CONFIG
##################################################

locals {
  ssm_default_tags = {
    ssm_connect_bad_ip              = "false"
    ssm_connect_enumerate_host      = "false"
    ssm_connect_oast_host           = "false"
    ssm_connect_codecov             = "false"
    ssm_deploy_malware_eicar        = "false"
    ssm_deploy_secret_ssh_public    = "false"
    ssm_deploy_secret_ssh_private   = "false"
    ssm_deploy_secret_aws_credentials     = "false"
    ssm_exec_responder_reverse_shell = "false"
    ssm_exec_reverse_shell_multistage_attacker = "false"
    ssm_exec_reverse_shell   = "false"
    ssm_exec_responder_http_listener = "false"
    ssm_exec_docker_cpuminer        = "false"
    ssm_deploy_python3_twisted_app = "false"
    ssm_deploy_rds_app = "false"
    ssm_exec_docker_guardduty = "false"
    ssm_deploy_docker_log4j_app = "false"
    ssm_exec_docker_exploit_log4j_app = "false"
    ssm_deploy_log4j_app = "false"
    ssm_deploy_npm_app    = "false"
    ssm_exec_exploit_npm_app  = "false"
    ssm_deploy_inspector_agent      = "false"
    ssm_deploy_docker               = "false"
    ssm_deploy_git                  = "false"
    ssm_deploy_lacework             = "false"
    ssm_deploy_lacework_syscall   = "false"
    ssm_deploy_lacework_code_aware_agent = "false"
    ssm_deploy_aws_cli        = "false"
    ssm_deploy_lacework_cli   = "false"
    ssm_deploy_kubectl_cli    = "false"
    ssm_exec_port_forward    = "false"
    ssm_exec_responder_port_forward  = "false"
    ssm_exec_docker_compromised_keys = "false"
    ssm_exec_docker_defense_evasion = "false"
    ssm_exec_docker_cloud_ransomware = "false"
    ssm_exec_docker_cloud_cryptomining = "false"
    ssm_exec_docker_host_cryptomining = "false"
    ssm_exec_docker_host_compromise = "false"
    ssm_exec_generate_aws_cli_traffic_target = "false"
    ssm_exec_generate_aws_cli_traffic_attacker = "false"
    ssm_exec_generate_web_traffic_target  = "false"
    ssm_exec_generate_web_traffic_attacker  = "false"
    ssm_exec_docker_hydra_attacker = "false"
    ssm_exec_docker_hydra_target = "false"
    ssm_exec_docker_nmap_attacker = "false"
    ssm_exec_docker_nmap_target = "false"
  }
  osconfig_default_tags = {
    osconfig_connect_bad_ip              = "false"
    osconfig_connect_enumerate_host      = "false"
    osconfig_connect_oast_host           = "false"
    osconfig_connect_codecov             = "false"
    osconfig_deploy_malware_eicar        = "false"
    osconfig_deploy_secret_ssh_public    = "false"
    osconfig_deploy_secret_ssh_private   = "false"
    osconfig_deploy_secret_gcp_credentials     = "false"
    osconfig_exec_responder_reverse_shell = "false"
    osconfig_exec_reverse_shell_multistage_attacker = "false"
    osconfig_exec_reverse_shell   = "false"
    osconfig_exec_git_codecov_target     = "false"
    osconfig_exec_responder_http_listener = "false"
    osconfig_exec_docker_cpuminer        = "false"
    osconfig_deploy_python3_twisted_app = "false"
    osconfig_deploy_docker_log4j_app = "false"
    osconfig_exec_docker_exploit_log4j_app = "false"
    osconfig_deploy_log4j_app  = "false"
    osconfig_deploy_npm_app    = "false"
    osconfig_exec_exploit_npm_app  = "false"
    osconfig_deploy_inspector_agent      = "false"
    osconfig_deploy_docker               = "false"
    osconfig_deploy_git                  = "false"
    osconfig_deploy_lacework             = "false"
    osconfig_deploy_lacework_syscall   = "false"
    osconfig_deploy_lacework_code_aware_agent = "false"
    osconfig_deploy_aws_cli        = "false"
    osconfig_deploy_lacework_cli   = "false"
    osconfig_deploy_kubectl_cli    = "false"
    osconfig_exec_port_forward    = "false"
    osconfig_exec_responder_port_forward  = "false"
    osconfig_exec_docker_compromised_keys = "false"
    osconfig_exec_docker_defense_evasion = "false"
    osconfig_exec_docker_cloud_ransomware = "false"
    osconfig_exec_docker_cloud_cryptomining = "false"
    osconfig_exec_docker_host_cryptomining = "false"
    osconfig_exec_docker_host_compromise = "false"
    osconfig_exec_generate_aws_cli_traffic_target = "false"
    osconfig_exec_generate_aws_cli_traffic_attacker = "false"
    osconfig_exec_generate_web_traffic_target  = "false"
    osconfig_exec_generate_web_traffic_attacker  = "false"
    osconfig_exec_docker_hydra = "false"
    osconfig_exec_docker_nmap = "false"
  }
  runbook_default_tags = {
    runbook_exec_touch_file                  = "false"
    runbook_connect_bad_ip              = "false"
    runbook_connect_enumerate_host      = "false"
    runbook_connect_oast_host           = "false"
    runbook_connect_codecov             = "false"
    runbook_deploy_malware_eicar        = "false"
    runbook_deploy_secret_ssh_public    = "false"
    runbook_deploy_secret_ssh_private   = "false"
    runbook_deploy_secret_aws_credentials     = "false"
    runbook_exec_responder_reverse_shell = "false"
    runboook_exec_reverse_shell_multistage_attacker = "false"
    runbook_exec_reverse_shell_target   = "false"
    runbook_exec_git_codecov_target     = "false"
    runbook_exec_responder_http_listener_attacker = "false"
    runbook_exec_docker_cpuminer        = "false"
    runbook_exec_exploit_python3_twisted_app = "false"
    runbook_exec_docker_exploit_log4j_app = "false"
    runbook_deploy_docker_log4j_app = "false"
    runbook_deploy_log4j_app  = "false"
    runbook_deploy_npm_app_target    = "false"
    runbook_exec_exploit_npm_app  = "false"
    runbook_deploy_inspector_agent      = "false"
    runbook_deploy_docker               = "false"
    runbook_deploy_git                  = "false"
    runbook_deploy_lacework             = "false"
    runbook_deploy_lacework_syscall   = "false"
    runbook_deploy_lacework_code_aware_agent = "false"
    runbook_deploy_aws_cli        = "false"
    runbook_deploy_lacework_cli   = "false"
    runbook_deploy_kubectl_cli    = "false"
    runbook_exec_port_forward    = "false"
    runbook_exec_responder_port_forward  = "false"
    runbook_exec_docker_compromised_keys_attacker = "false"
    runbook_exec_docker_defense_evasion_attacker = "false"
    runbook_exec_docker_cloud_ransomware_attacker = "false"
    runbook_exec_docker_cloud_cryptomining_attacker = "false"
    runbook_exec_docker_host_cryptomining_attacker = "false"
    runbook_exec_generate_aws_cli_traffic_target = "false"
    runbook_exec_generate_aws_cli_traffic_attacker = "false"
    runbook_exec_generate_web_traffic_target  = "false"
    runbook_exec_generate_web_traffic_attacker  = "false"
    runbook_exec_docker_hydra = "false"
    runbook_exec_docker_nmap = "false"
  }
}