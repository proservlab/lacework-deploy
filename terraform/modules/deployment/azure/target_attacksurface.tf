locals {
  target_attacksurface_config = var.target_attacksurface_config
  target_automation_account  = module.target-automation-account

  target_resource_group = try(module.target-compute[0].resource_group, null)
  target_public_security_group = try(module.target-compute[0].public_security_group, null)
  target_private_security_group = try(module.target-compute[0].private_security_group, null)

  target_resource_app_group = try(module.target-compute[0].resource_app_group, null)
  target_public_app_security_group = try(module.target-compute[0].public_app_security_group, null)
  target_private_app_security_group = try(module.target-compute[0].private_app_security_group, null)
  target_instances = try(module.target-compute[0].instances, [])

  target_db_host = try(module.target-azuresql[0].sql_server.fqdn, null)
  target_db_name = try(module.target-azuresql[0].sql_server.name, null)
  target_db_user = try(module.target-azuresql[0].sql_user, null)
  target_db_password = try(module.target-azuresql[0].sql_password, null)
  target_db_port = try(module.target-azuresql[0].sql_port, null)
  target_db_region = try(module.target-azuresql[0].sql_region, null)

  # public target instances
  public_target_instances = flatten([
    [ for compute in local.target_instances: compute if compute.role == "default" && compute.public == "true" ]
  ])

  public_target_app_instances = flatten([
    [ for compute in local.target_instances: compute if compute.role == "app" && compute.public == "true" ]
  ])

  # target_aks_public_ip = try(["${local.target_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
  # target_aks_public_ip = try(["${local.target_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])
}

##################################################
# AZURE COMPUTE SECURITY GROUP
##################################################

# append ingress rules
module "target-compute-add-trusted-ingress" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.azure.compute.add_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/compute-add-trusted-ingress"
  environment     = local.target_attacksurface_config.context.global.environment
  deployment      = local.target_attacksurface_config.context.global.deployment

  resource_group                = local.target_automation_account[0].resource_group.name
  security_group                = local.target_public_security_group.name

  trusted_attacker_source       = local.target_attacksurface_config.context.azure.compute.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in try(local.public_attacker_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_attacker_app_instances, []): "${compute.public_ip}/32" ],
    # local.target_eks_public_ip
  ])  : []
  trusted_target_source         = local.target_attacksurface_config.context.azure.compute.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in try(local.public_target_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_target_app_instances, []): "${compute.public_ip}/32" ],
    # local.target_eks_public_ip
  ]) : []
  trusted_workstation_source    = local.target_attacksurface_config.context.azure.compute.add_trusted_ingress.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources    = length(local.target_attacksurface_config.context.azure.compute.add_trusted_ingress.additional_trusted_sources) > 0 ? local.target_attacksurface_config.context.azure.compute.add_trusted_ingress.additional_trusted_sources : []
  trusted_tcp_ports             = local.target_attacksurface_config.context.azure.compute.add_trusted_ingress.trusted_tcp_ports

  providers = {
    azurerm    = azurerm.target
  }

  depends_on = [
      module.attacker-compute,
      module.target-compute,
      module.attacker-aks,
      module.target-aks
  ]
}

module "target-compute-add-app-trusted-ingress" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.azure.compute.add_app_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/compute-add-trusted-ingress"
  environment     = local.target_attacksurface_config.context.global.environment
  deployment      = local.target_attacksurface_config.context.global.deployment

  resource_group                = module.target-compute[0].resource_app_group.name
  security_group                = local.target_public_app_security_group.name

  trusted_attacker_source       = local.target_attacksurface_config.context.azure.compute.add_app_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in try(local.public_attacker_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_attacker_app_instances, []): "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ])  : []
  trusted_target_source         = local.target_attacksurface_config.context.azure.compute.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for compute in try(local.public_target_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_target_app_instances, []): "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source    = local.target_attacksurface_config.context.azure.compute.add_app_trusted_ingress.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources    = length(local.target_attacksurface_config.context.azure.compute.add_app_trusted_ingress.additional_trusted_sources) > 0 ? local.target_attacksurface_config.context.azure.compute.add_app_trusted_ingress.additional_trusted_sources : []
  trusted_tcp_ports             = local.target_attacksurface_config.context.azure.compute.add_app_trusted_ingress.trusted_tcp_ports

  providers = {
    azurerm    = azurerm.target
  }

  depends_on = [
      module.attacker-compute,
      module.target-compute,
      module.attacker-aks,
      module.target-aks
  ]
}


##################################################
# AZURE RUNBOOK
##################################################

module "target-ssh-keys" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.azure.runbook.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-ssh-keys"
  environment     = local.target_attacksurface_config.context.global.environment
  deployment      = local.target_attacksurface_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region

  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  ssh_public_key_path = local.target_attacksurface_config.context.azure.runbook.ssh_keys.ssh_public_key_path
  ssh_private_key_path = local.target_attacksurface_config.context.azure.runbook.ssh_keys.ssh_private_key_path
  ssh_authorized_keys_path = local.target_attacksurface_config.context.azure.runbook.ssh_keys.ssh_authorized_keys_path

  private_tag = "runbook_deploy_secret_ssh_private"
  public_tag = "runbook_deploy_secret_ssh_public"

  providers = {
    azurerm    = azurerm.target
  }
}

module "target-ssh-user" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.azure.runbook.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-ssh-user"
  environment     = local.target_attacksurface_config.context.global.environment
  deployment      = local.target_attacksurface_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region

  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  tag = "runbook_deploy_ssh_user"

  username = local.target_attacksurface_config.context.azure.runbook.ssh_user.username
  password = local.target_attacksurface_config.context.azure.runbook.ssh_user.password

  providers = {
    azurerm    = azurerm.target
  }
}

##################################################
# AZURE RUNBOOK: Vulnerable Apps
##################################################

module "target-vulnerable-docker-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.azure.runbook.vulnerable.docker.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-docker-log4j-app"
  environment     = local.target_attacksurface_config.context.global.environment
  deployment      = local.target_attacksurface_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region

  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  tag = "runbook_deploy_docker_log4j_app"

  listen_port = local.target_attacksurface_config.context.azure.runbook.vulnerable.docker.log4j_app.listen_port

  providers = {
    azurerm    = azurerm.target
  }
}

module "target-vulnerable-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.azure.runbook.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-log4j-app"
  environment     = local.target_attacksurface_config.context.global.environment
  deployment      = local.target_attacksurface_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region

  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  tag = "runbook_deploy_log4j_app"

  listen_port = local.target_attacksurface_config.context.azure.runbook.vulnerable.log4j_app.listen_port

  providers = {
    azurerm    = azurerm.target
  }
}

module "target-vulnerable-npm-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.azure.runbook.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-npm-app"
  environment     = local.target_attacksurface_config.context.global.environment
  deployment      = local.target_attacksurface_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region

  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  tag = "runbook_deploy_npm_app"

  listen_port = local.target_attacksurface_config.context.azure.runbook.vulnerable.npm_app.listen_port
  providers = {
    azurerm    = azurerm.target
  }
}

module "target-vulnerable-python3-twisted-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.azure.runbook.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-python3-twisted-app"
  environment     = local.target_attacksurface_config.context.global.environment
  deployment      = local.target_attacksurface_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region

  resource_group  = local.target_automation_account[0].resource_group
  automation_account = local.target_automation_account[0].automation_account_name
  automation_princial_id = local.target_automation_account[0].automation_princial_id

  tag = "runbook_deploy_python3_twisted_app"

  listen_port = local.target_attacksurface_config.context.azure.runbook.vulnerable.python3_twisted_app.listen_port
  
  providers = {
    azurerm    = azurerm.target
  }
}

##################################################
# Kubernetes General
##################################################

module "target-target-kubernetes-reloader" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.azure.reloader.enabled == true ) ? 1 : 0
  source      = "../common/kubernetes-reloader"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment

  depends_on = [
    module.target-aks,
    # module.target-iam,
  ]

  providers = {
    kubernetes    = kubernetes.target
    helm          = helm.target
  }
}

# example of pushing kubernetes deployment via terraform
module "target-kubernetes-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.gcp.app.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment

  container_port                = 80 
  service_port                  = local.target_attacksurface_config.context.kubernetes.azure.app.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.azure.app.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.azure.app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.target_attacksurface_config.context.kubernetes.azure.app.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.kubernetes.azure.app.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.target_attacksurface_config.context.kubernetes.azure.app.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.azure.app.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.target_attacksurface_config.context.kubernetes.azure.app.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.azure.app.additional_trusted_sources

  image                         = local.target_attacksurface_config.context.kubernetes.azure.app.image
  command                       = local.target_attacksurface_config.context.kubernetes.azure.app.command
  args                          = local.target_attacksurface_config.context.kubernetes.azure.app.args
  privileged                    = local.target_attacksurface_config.context.kubernetes.azure.app.privileged
  allow_privilege_escalation    = local.target_attacksurface_config.context.kubernetes.azure.app.allow_allow_privilege_escalation

  dynu_api_key    = local.target_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.target_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.azure.app

  depends_on = [
    module.target-aks,
    # module.target-iam,
  ]

  providers = {
    kubernetes    = kubernetes.target
    helm          = helm.target
    restapi       = restapi.main
  }
}

##################################################
# Kubernetes GCP Vulnerable
##################################################

# module "target-vulnerable-kubernetes-voteapp" {
#   count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
#   source      = "../kubernetes/gcp/vulnerable/voteapp"
#   environment                   = local.target_attacksurface_config.context.global.environment
#   deployment                    = local.target_attacksurface_config.context.global.deployment
#   region                        = local.target_attacksurface_config.context.aws.region
#   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
#   secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

#   vote_service_port             = local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.vote_service_port
#   result_service_port           = local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.result_service_port
#   trusted_target_source       = local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.trust_target_source ? flatten([
#     [ for ip in data.aws_instances.public_target[0].public_ips: "${ip}/32" ],
#     local.target_eks_public_ip
#   ])  : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources

    # providers = {
    #   kubernetes = kubernetes.main
    #   helm = helm.main
    # }
# }

module "target-vulnerable-kubernetes-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source                        = "./modules/kubernetes-log4j-app"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment

  container_port                = 8080 
  service_port                  = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ])  : []
  trusted_target_source_enabled = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.additional_trusted_sources

  dynu_api_key    = local.target_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.target_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.enable_dynu_dns

  depends_on = [
    module.target-aks,
    # module.target-iam,
  ]

  providers = {
    kubernetes    = kubernetes.target
    helm          = helm.target
    restapi       = restapi.main
  }
}

module "target-vulnerable-kubernetes-privileged-pod" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-privileged-pod"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment

  service_port                  = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.additional_trusted_sources

  image                         = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.image
  command                       = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.command
  args                          = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.args
  privileged                    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.privileged
  allow_privilege_escalation    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.allow_allow_privilege_escalation

  dynu_api_key    = local.target_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.target_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod

  depends_on = [
    module.target-aks,
    # module.target-iam,
  ]

  providers = {
    kubernetes    = kubernetes.target
    helm          = helm.target
    restapi       = restapi.main
  }
}

module "target-vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.azure.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-root-mount-fs-pod"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment

  container_port                = 80 
  service_port                  = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.service_port
  trusted_attacker_source_enabled = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_attacker_source
  trusted_attacker_source       = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_target_source
  trusted_target_source         = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_workstation_source
  trusted_workstation_source    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.additional_trusted_sources

  image                         = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.image
  command                       = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.command
  args                          = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.args
  privileged                    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.privileged
  allow_privilege_escalation    = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.allow_allow_privilege_escalation

  dynu_api_key    = local.target_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.target_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.target_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod

  depends_on = [
    module.target-aks,
    # module.target-iam,
  ]

  providers = {
    kubernetes    = kubernetes.target
    helm          = helm.target
    restapi       = restapi.main
  }
}