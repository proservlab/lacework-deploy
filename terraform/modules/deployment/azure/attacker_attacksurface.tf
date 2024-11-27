locals {
  attacker_attacksurface_config = var.attacker_attacksurface_config
  attacker_automation_account  = module.attacker-automation-account

  attacker_resource_group = try(module.attacker-compute[0].resource_group, null)
  attacker_public_security_group = try(module.attacker-compute[0].public_security_group, null)
  attacker_private_security_group = try(module.attacker-compute[0].private_security_group, null)
  attacker_private_nat_gw_ip = try(["${module.attacker-compute[0].private_nat_gw.address}/32"], [])

  attacker_resource_app_group = try(module.attacker-compute[0].resource_app_group, null)
  attacker_public_app_security_group = try(module.attacker-compute[0].public_app_security_group, null)
  attacker_private_app_security_group = try(module.attacker-compute[0].private_app_security_group, null)
  attacker_private_app_nat_gw_ip = try(["${module.attacker-compute[0].private_app_nat_gw.address}/32"], [])
  
  attacker_instances = try(module.attacker-compute[0].instances, [])

  attacker_db_host = try(module.attacker-azuresql[0].sql_server.fqdn, null)
  attacker_db_name = try(module.attacker-azuresql[0].sql_server.name, null)
  attacker_db_user = try(module.attacker-azuresql[0].sql_user, null)
  attacker_db_password = try(module.attacker-azuresql[0].sql_password, null)
  attacker_db_port = try(module.attacker-azuresql[0].sql_port, null)
  attacker_db_region = try(module.attacker-azuresql[0].sql_region, null)

  # public attacker instances
  public_attacker_instances = flatten([
    [ for compute in local.attacker_instances: compute if compute.role == "default" && compute.public == "true" ]
  ])

  public_attacker_app_instances = flatten([
    [ for compute in local.attacker_instances: compute if compute.role == "app" && compute.public == "true" ]
  ])
  
  # attacker_aks_public_ip = try(["${local.attacker_infrastructure_deployed.context.azure.aks[0].cluster_nat_public_ip}/32"],[])

  attacker_compromised_credentials = try(module.attacker-iam[0].access_keys, {})
}

##################################################
# AZURE COMPUTE SECURITY GROUP
##################################################

# append ingress rules
module "attacker-compute-add-trusted-ingress" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.compute.add_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/compute-add-trusted-ingress"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment

  resource_group                = local.attacker_automation_account[0].resource_group.name
  security_group                = local.attacker_public_security_group.name

  trusted_attacker_source       = local.attacker_attacksurface_config.context.azure.compute.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in try(local.public_attacker_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_attacker_app_instances, []): "${compute.public_ip}/32" ],
    local.attacker_private_nat_gw_ip,
    local.attacker_private_app_nat_gw_ip
    # local.attacker_eks_public_ip
  ])  : []
  trusted_target_source         = local.attacker_attacksurface_config.context.azure.compute.add_trusted_ingress.trust_target_source ? flatten([
    [ for compute in try(local.public_target_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_target_app_instances, []): "${compute.public_ip}/32" ],
    local.target_private_nat_gw_ip,
    local.target_private_app_nat_gw_ip
    # local.target_eks_public_ip
  ]) : []
  trusted_workstation_source    = local.attacker_attacksurface_config.context.azure.compute.add_trusted_ingress.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources    = length(local.attacker_attacksurface_config.context.azure.compute.add_trusted_ingress.additional_trusted_sources) > 0 ? local.attacker_attacksurface_config.context.azure.compute.add_trusted_ingress.additional_trusted_sources : []
  trusted_tcp_ports             = local.attacker_attacksurface_config.context.azure.compute.add_trusted_ingress.trusted_tcp_ports

  providers = {
    azurerm    = azurerm.attacker
  }

  depends_on = [
      module.attacker-compute,
      module.target-compute,
      module.attacker-aks,
      module.target-aks
  ]
}

module "attacker-compute-add-app-trusted-ingress" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.compute.add_app_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/compute-add-trusted-ingress"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment

  resource_group                = module.attacker-compute[0].resource_app_group.name
  security_group                = local.attacker_public_app_security_group.name

  trusted_attacker_source       = local.attacker_attacksurface_config.context.azure.compute.add_app_trusted_ingress.trust_attacker_source ? flatten([
    [ for compute in try(local.public_attacker_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_attacker_app_instances, []): "${compute.public_ip}/32" ],
    local.attacker_private_nat_gw_ip,
    local.attacker_private_app_nat_gw_ip
    # local.attacker_aks_public_ip
  ])  : []
  trusted_target_source         = local.attacker_attacksurface_config.context.azure.compute.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for compute in try(local.public_target_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_target_app_instances, []): "${compute.public_ip}/32" ],
    local.target_private_nat_gw_ip,
    local.target_private_app_nat_gw_ip
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source    = local.attacker_attacksurface_config.context.azure.compute.add_app_trusted_ingress.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources    = length(local.attacker_attacksurface_config.context.azure.compute.add_app_trusted_ingress.additional_trusted_sources) > 0 ? local.attacker_attacksurface_config.context.azure.compute.add_app_trusted_ingress.additional_trusted_sources : []
  trusted_tcp_ports             = local.attacker_attacksurface_config.context.azure.compute.add_app_trusted_ingress.trusted_tcp_ports

  providers = {
    azurerm    = azurerm.attacker
  }

  depends_on = [
      module.attacker-compute,
      module.target-compute,
      module.attacker-aks,
      module.target-aks
  ]
}

##################################################
# AZURE IAM
##################################################

# create iam users
module "attacker-iam" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.iam.enabled == true ) ? 1 : 0
  source      = "./modules/iam"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region

  user_policies     = jsondecode(templatefile(local.attacker_attacksurface_config.context.azure.iam.user_policies_path, { environment = local.attacker_attacksurface_config.context.global.environment, deployment = local.attacker_attacksurface_config.context.global.deployment }))
  users             = jsondecode(templatefile(local.attacker_attacksurface_config.context.azure.iam.users_path, { environment = local.attacker_attacksurface_config.context.global.environment, deployment = local.attacker_attacksurface_config.context.global.deployment }))

  providers = {
    azuread = azuread.attacker
    azurerm = azurerm.attacker
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

module "attacker-ssh-keys" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.runbook.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-ssh-keys"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region

  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  ssh_public_key_path = local.attacker_attacksurface_config.context.azure.runbook.ssh_keys.ssh_public_key_path
  ssh_private_key_path = local.attacker_attacksurface_config.context.azure.runbook.ssh_keys.ssh_private_key_path
  ssh_authorized_keys_path = local.attacker_attacksurface_config.context.azure.runbook.ssh_keys.ssh_authorized_keys_path

  private_tag = "runbook_deploy_secret_ssh_private"
  public_tag = "runbook_deploy_secret_ssh_public"

  providers = {
    azurerm    = azurerm.attacker
  }
}

module "attacker-ssh-user" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.runbook.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-ssh-user"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region

  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  tag = "runbook_deploy_ssh_user"

  username = local.attacker_attacksurface_config.context.azure.runbook.ssh_user.username
  password = local.attacker_attacksurface_config.context.azure.runbook.ssh_user.password

  providers = {
    azurerm    = azurerm.attacker
  }
}

module "attacker-azure-credentials" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.runbook.azure_credentials.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-azure-credentials"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region

  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  tag = "runbook_deploy_secret_azure_credentials"

  compromised_credentials = local.attacker_compromised_credentials
  compromised_keys_user = local.attacker_attacksurface_config.context.azure.runbook.azure_credentials.compromised_keys_user

  depends_on = [ 
    module.target-iam,
    module.attacker-iam 
  ]

  providers = {
    azurerm    = azurerm.attacker
  }
}

##################################################
# AZURE RUNBOOK: Vulnerable Apps
##################################################

module "attacker-vulnerable-docker-log4j-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.runbook.vulnerable.docker.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-docker-log4j-app"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region

  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  tag = "runbook_deploy_docker_log4j_app"

  listen_port = local.attacker_attacksurface_config.context.azure.runbook.vulnerable.docker.log4j_app.listen_port

  # trust attacker addresses - these are used to in nginx to allow exploit only by attacker
  trusted_addresses = flatten([
    [ for compute in try(local.public_target_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_target_app_instances, []): "${compute.public_ip}/32" ],
    local.target_private_nat_gw_ip,
    local.target_private_app_nat_gw_ip,
    # local.target_aks_public_ip,
    [ for address in local.attacker_attacksurface_config.context.azure.runbook.vulnerable.docker.log4j_app.trusted_addresses:  "${address}/32" ]
  ])

  providers = {
    azurerm    = azurerm.attacker
  }
}

module "attacker-vulnerable-log4j-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.runbook.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-log4j-app"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region

  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  tag = "runbook_deploy_log4j_app"

  listen_port = local.attacker_attacksurface_config.context.azure.runbook.vulnerable.log4j_app.listen_port

  # trust attacker addresses - these are used to in nginx to allow exploit only by attacker
  trusted_addresses = flatten([
    [ for compute in try(local.public_target_instances, []): "${compute.public_ip}/32" ],
    [ for compute in try(local.public_target_app_instances, []): "${compute.public_ip}/32" ],
    local.target_private_nat_gw_ip,
    local.target_private_app_nat_gw_ip,
    # local.target_aks_public_ip,
    [ for address in local.attacker_attacksurface_config.context.azure.runbook.vulnerable.log4j_app.trusted_addresses:  "${address}/32" ]
  ])

  providers = {
    azurerm    = azurerm.attacker
  }
}

module "attacker-vulnerable-npm-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.runbook.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-npm-app"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region

  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  tag = "runbook_deploy_npm_app"

  listen_port = local.attacker_attacksurface_config.context.azure.runbook.vulnerable.npm_app.listen_port
  providers = {
    azurerm    = azurerm.attacker
  }
}

module "attacker-vulnerable-python3-twisted-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.azure.runbook.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/runbook/deploy-python3-twisted-app"
  environment     = local.attacker_attacksurface_config.context.global.environment
  deployment      = local.attacker_attacksurface_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region

  resource_group  = local.attacker_automation_account[0].resource_group
  automation_account = local.attacker_automation_account[0].automation_account_name
  automation_princial_id = local.attacker_automation_account[0].automation_princial_id

  tag = "runbook_deploy_python3_twisted_app"

  listen_port = local.attacker_attacksurface_config.context.azure.runbook.vulnerable.python3_twisted_app.listen_port
  
  providers = {
    azurerm    = azurerm.attacker
  }
}

##################################################
# Kubernetes General
##################################################

module "attacker-attacker-kubernetes-reloader" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.azure.reloader.enabled == true ) ? 1 : 0
  source      = "../common/kubernetes-reloader"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment

  depends_on = [
    module.attacker-aks,
    # module.attacker-iam,
  ]

  providers = {
    kubernetes    = kubernetes.attacker
    helm          = helm.attacker
  }
}

# example of pushing kubernetes deployment via terraform
module "attacker-kubernetes-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.gcp.app.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-app"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment

  container_port                = 80 
  service_port                  = local.attacker_attacksurface_config.context.kubernetes.azure.app.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.azure.app.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.azure.app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    # local.attacker_aks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.attacker_attacksurface_config.context.kubernetes.azure.app.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.azure.app.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.attacker_attacksurface_config.context.kubernetes.azure.app.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.azure.app.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.kubernetes.azure.app.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.azure.app.additional_trusted_sources

  image                         = local.attacker_attacksurface_config.context.kubernetes.azure.app.image
  command                       = local.attacker_attacksurface_config.context.kubernetes.azure.app.command
  args                          = local.attacker_attacksurface_config.context.kubernetes.azure.app.args
  privileged                    = local.attacker_attacksurface_config.context.kubernetes.azure.app.privileged
  allow_privilege_escalation    = local.attacker_attacksurface_config.context.kubernetes.azure.app.allow_allow_privilege_escalation

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.azure.app

  depends_on = [
    module.attacker-aks,
    # module.attacker-iam,
  ]

  providers = {
    kubernetes    = kubernetes.attacker
    helm          = helm.attacker
    restapi       = restapi.main
  }
}

##################################################
# Kubernetes AZURE Vulnerable
##################################################

# module "attacker-vulnerable-kubernetes-voteapp" {
#   count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
#   source      = "../kubernetes/gcp/vulnerable/voteapp"
#   environment                   = local.attacker_attacksurface_config.context.global.environment
#   deployment                    = local.attacker_attacksurface_config.context.global.deployment
#   region                        = local.attacker_attacksurface_config.context.aws.region
#   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
#   secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

#   vote_service_port             = local.attacker_attacksurface_config.context.kubernetes.vulnerable.voteapp.vote_service_port
#   result_service_port           = local.attacker_attacksurface_config.context.kubernetes.vulnerable.voteapp.result_service_port
#   trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
#     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_eks_public_ip
#   ])  : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources

    # providers = {
    #   kubernetes = kubernetes.main
    #   helm = helm.main
    # }
# }

module "attacker-vulnerable-kubernetes-log4j-app" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source                        = "./modules/kubernetes-log4j-app"
  environment                   = local.attacker_attacksurface_config.context.global.environment
  deployment                    = local.attacker_attacksurface_config.context.global.deployment

  container_port                = 8080 
  service_port                  = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    # local.attacker_aks_public_ip
  ])  : []
  trusted_target_source_enabled = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source_enabled = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.trust_workstation_source ? [module.workstation-external-ip.cidr] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.additional_trusted_sources) > 0 ? true : false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.additional_trusted_sources

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.log4j_app.enable_dynu_dns

  depends_on = [
    module.attacker-aks,
    # module.attacker-iam,
  ]

  providers = {
    kubernetes    = kubernetes.attacker
    helm          = helm.attacker
    restapi       = restapi.main
  }
}

module "attacker-vulnerable-kubernetes-privileged-pod" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-privileged-pod"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment

  service_port                  = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    # local.attacker_aks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.additional_trusted_sources

  image                         = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.image
  command                       = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.command
  args                          = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.args
  privileged                    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.privileged
  allow_privilege_escalation    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.allow_allow_privilege_escalation

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod

  depends_on = [
    module.attacker-aks,
    # module.attacker-iam,
  ]

  providers = {
    kubernetes    = kubernetes.attacker
    helm          = helm.attacker
    restapi       = restapi.main
  }
}

module "attacker-vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.attacker_attacksurface_config.context.global.enable_all == true) || (local.attacker_attacksurface_config.context.global.disable_all != true && local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "./modules/kubernetes-root-mount-fs-pod"
  environment = local.attacker_attacksurface_config.context.global.environment
  deployment  = local.attacker_attacksurface_config.context.global.deployment

  container_port                = 80 
  service_port                  = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.service_port
  trusted_attacker_source_enabled = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_attacker_source
  trusted_attacker_source       = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_attacker_source ? flatten([
    [ for compute in local.public_attacker_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_attacker_app_instances: "${compute.public_ip}/32" ],
    # local.attacker_aks_public_ip,
  ])  : []
  trusted_target_source_enabled  = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_target_source
  trusted_target_source         = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_target_source ? flatten([
    [ for compute in local.public_target_instances: "${compute.public_ip}/32" ],
    [ for compute in local.public_target_app_instances: "${compute.public_ip}/32" ],
    # local.target_aks_public_ip
  ]) : []
  trusted_workstation_source_enabled    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_workstation_source
  trusted_workstation_source    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources_enabled = length(local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.additional_trusted_sources) > 0 ? true: false
  additional_trusted_sources    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.additional_trusted_sources

  image                         = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.image
  command                       = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.command
  args                          = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.args
  privileged                    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.privileged
  allow_privilege_escalation    = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod.allow_allow_privilege_escalation

  dynu_api_key    = local.attacker_infrastructure_config.context.dynu_dns.api_key
  dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  enable_dynu_dns = local.attacker_attacksurface_config.context.kubernetes.azure.vulnerable.privileged_pod

  depends_on = [
    module.attacker-aks,
    # module.attacker-iam,
  ]

  providers = {
    kubernetes    = kubernetes.attacker
    helm          = helm.attacker
    restapi       = restapi.main
  }
}
