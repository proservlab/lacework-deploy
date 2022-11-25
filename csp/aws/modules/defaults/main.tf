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
        ssm_exec_git_codecov            = "false"
        ssm_exec_http_listener_attacker = "false"
        ssm_exec_docker_cpuminer        = "false"
        ssm_deploy_inspector_agent      = "false"
        ssm_deploy_docker               = "false"
        ssm_deploy_git                  = "false"
  }
}