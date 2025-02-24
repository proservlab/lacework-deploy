##################################################
# LOCALS
##################################################

locals {
  attacker_infrastructure_config                = var.attacker_infrastructure_config
  attacker_kubeconfig                           = pathexpand("~/.kube/azure-attacker-${local.attacker_infrastructure_config.context.global.deployment}-kubeconfig")
  attacker_cluster_name                         = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster.id : null
  attacker_cluster_endpoint                     = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster.endpoint : null
  attacker_cluster_ca_cert                      = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster.certificate_authority[0].data : null
  attacker_cluster_oidc_issuer                  = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster.identity[0].oidc[0].issuer : null
  attacker_cluster_security_group               = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster_sg_id : null
  attacker_cluster_vpc_id                       = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster_vpc_id : null
  attacker_cluster_vpc_subnet                   = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster_vpc_subnet : null
  attacker_cluster_openid_connect_provider_arn  = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster_openid_connect_provider.arn : null
  attacker_cluster_openid_connect_provider_url  = local.attacker_infrastructure_config.context.azure.aks.enabled ? module.attacker-aks[0].cluster_openid_connect_provider.url : null
  attacker_tenant_id                            = var.attacker_azure_tenant
  attacker_subscription_id                      = var.attacker_azure_subscription
}

##################################################
# AZURE RUNBOOK SIMULATION
##################################################

module "attacker-automation-account" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  source          = "./modules/automation/account"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-resource-group.resource_group

  depends_on = [
    module.attacker-compute,
    module.attacker-resource-group
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}

##################################################
# AZURE Resource Group
##################################################

module "attacker-resource-group" {
  source = "./modules/resource-group"
  name = "resource-group"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment
  region       = local.attacker_infrastructure_config.context.azure.region
  
  providers = {
    azurerm = azurerm.attacker
  }
}

# module "attacker-resource-group-app" {
#   source = "./modules/resource-group"
#   name = "resource-group-app"
#   environment  = local.attacker_infrastructure_config.context.global.environment
#   deployment   = local.attacker_infrastructure_config.context.global.deployment
#   region       = local.attacker_infrastructure_config.context.azure.region

#   providers = {
#     azurerm = azurerm.attacker
#   }
# }

##################################################
# AZURE COMPUTE
##################################################

# compute
module "attacker-compute" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  source       = "./modules/compute"
  environment  = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment
  region       = local.attacker_infrastructure_config.context.azure.region
  
  # list of instances to configure
  instances = local.attacker_infrastructure_config.context.azure.compute.instances

  # allow endpoints inside their own security group to communicate
  trust_security_group = local.attacker_infrastructure_config.context.global.trust_security_group

  public_ingress_rules = local.attacker_infrastructure_config.context.azure.compute.public_ingress_rules
  public_egress_rules = local.attacker_infrastructure_config.context.azure.compute.public_egress_rules
  public_app_ingress_rules = local.attacker_infrastructure_config.context.azure.compute.public_app_ingress_rules
  public_app_egress_rules = local.attacker_infrastructure_config.context.azure.compute.public_app_egress_rules
  private_ingress_rules = local.attacker_infrastructure_config.context.azure.compute.private_ingress_rules
  private_egress_rules = local.attacker_infrastructure_config.context.azure.compute.private_egress_rules
  private_app_ingress_rules = local.attacker_infrastructure_config.context.azure.compute.private_app_ingress_rules
  private_app_egress_rules = local.attacker_infrastructure_config.context.azure.compute.private_app_egress_rules

  public_network = local.attacker_infrastructure_config.context.azure.compute.public_network
  public_subnet = local.attacker_infrastructure_config.context.azure.compute.public_subnet
  public_app_network = local.attacker_infrastructure_config.context.azure.compute.public_app_network
  public_app_subnet = local.attacker_infrastructure_config.context.azure.compute.public_app_subnet
  private_network = local.attacker_infrastructure_config.context.azure.compute.private_network
  private_subnet = local.attacker_infrastructure_config.context.azure.compute.private_subnet
  private_nat_subnet = local.attacker_infrastructure_config.context.azure.compute.private_nat_subnet
  private_app_network = local.attacker_infrastructure_config.context.azure.compute.private_app_network
  private_app_subnet = local.attacker_infrastructure_config.context.azure.compute.private_app_subnet
  private_app_nat_subnet = local.attacker_infrastructure_config.context.azure.compute.private_app_nat_subnet

  resource_group = module.attacker-resource-group.resource_group
  resource_app_group = module.attacker-resource-group.resource_group

  enable_dynu_dns                     = local.attacker_infrastructure_config.context.dynu_dns.enabled
  dynu_dns_domain                     = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
  dynu_api_key                        = local.attacker_infrastructure_config.context.dynu_dns.api_key

  depends_on = [
    module.attacker-resource-group
  ]

  providers = {
    azurerm = azurerm.attacker
    restapi = restapi.main
  }
}

##################################################
# AZURE SQL
##################################################

module "attacker-azuresql" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.azuresql.enabled == true ) ? 1 : 0
  source                              = "./modules/azuresql"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment
  region                              = local.attacker_infrastructure_config.context.azure.region
  server_name                         = local.attacker_infrastructure_config.context.azure.azuresql.server_name
  db_name                             = local.attacker_infrastructure_config.context.azure.azuresql.db_name
  db_resource_group_name              = module.attacker-resource-group.resource_group.name
  db_virtual_network_name             = module.attacker-compute[0].public_app_virtual_network.name
  db_virtual_network_id               = module.attacker-compute[0].public_app_virtual_network.id
  db_subnet_network                   = [cidrsubnet(local.attacker_infrastructure_config.context.azure.compute.public_app_network,8,200)]

  instance_type                       = local.attacker_infrastructure_config.context.azure.azuresql.instance_type
  sku_name                            = local.attacker_infrastructure_config.context.azure.azuresql.sku_name
  public_network_access_enabled       = local.attacker_infrastructure_config.context.azure.azuresql.public_network_access_enabled

  add_service_principal_access        = try(length(local.attacker_infrastructure_config.context.azure.azuresql.service_principal_name), "false") != "false" ? true : false
  service_principal_display_name      = try(length(local.attacker_infrastructure_config.context.azure.azuresql.service_principal_name), "false") != "false" ?  module.attacker-iam[0].service_principal_ids[local.attacker_infrastructure_config.context.azure.azuresql.service_principal_name].display_name : null

  mysql_authorized_ip_ranges          = local.attacker_infrastructure_config.context.azure.azuresql.instance_type == "mysql" ?[ for ip in flatten([
    [ for compute in try(local.public_attacker_instances, []): "${compute.public_ip}" ],
    [ for compute in try(local.public_attacker_app_instances, []): "${compute.public_ip}" ],
    [ for compute in try(local.public_target_instances, []): "${compute.public_ip}" ],
    [ for compute in try(local.public_target_app_instances, []): "${compute.public_ip}" ],
    [module.workstation-external-ip.ip]
  ]) :  {
          start_ip_address = ip
          end_ip_address = ip
        }
  ] : []

  postgres_authorized_ip_ranges         = local.attacker_infrastructure_config.context.azure.azuresql.instance_type == "postgres" ?[ for ip in flatten([
    [ for compute in try(local.public_attacker_instances, []): "${compute.public_ip}" ],
    [ for compute in try(local.public_attacker_app_instances, []): "${compute.public_ip}" ],
    [ for compute in try(local.public_target_instances, []): "${compute.public_ip}" ],
    [ for compute in try(local.public_target_app_instances, []): "${compute.public_ip}" ],
    [module.workstation-external-ip.ip]
  ]) :  {
          start_ip_address = ip
          end_ip_address = ip
        }
  ] : []

  depends_on = [ 
    module.attacker-compute,
    module.target-compute,
    module.target-iam,
    module.attacker-iam
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}

##################################################
# AZURE SQL
##################################################

module "attacker-azurestorage" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.azurestorage.enabled == true ) ? 1 : 0
  source                              = "./modules/azurestorage"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment
  region                              = local.attacker_infrastructure_config.context.azure.region
  storage_resource_group_name         = module.attacker-resource-group.resource_group.name
  storage_virtual_network_name        = module.attacker-compute[0].public_app_virtual_network.name
  storage_virtual_network_id          = module.attacker-compute[0].public_app_virtual_network.id
  storage_subnet_network              = [cidrsubnet(local.attacker_infrastructure_config.context.azure.compute.public_app_network,8,201)]

  account_replication_type            = local.attacker_infrastructure_config.context.azure.azurestorage.account_replication_type
  account_tier                        = local.attacker_infrastructure_config.context.azure.azurestorage.account_tier
  public_network_access_enabled       = local.attacker_infrastructure_config.context.azure.azurestorage.public_network_access_enabled
  
  # add the local workstation and all public addresses for compute instances
  trusted_networks                    = flatten([
    [ replace(module.workstation-external-ip.cidr,"/32","") ],
    [ for instance in try(module.attacker-compute[0].instances, []): replace(instance.public_ip,"/32","") if instance.role == "app" && instance.public == "true"],
    [ for instance in try(module.attacker-compute[0].instances, []): replace(instance.public_ip,"/32","") if instance.role == "default" && instance.public == "true"]
  ])

  depends_on = [ module.attacker-compute ]

  providers = {
    azurerm = azurerm.attacker
  }
}

##################################################
# AZURE AKS
##################################################

module "attacker-aks" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.aks.enabled == true ) ? 1 : 0
  source                              = "./modules/aks"
  environment                         = local.attacker_infrastructure_config.context.global.environment
  deployment                          = local.attacker_infrastructure_config.context.global.deployment
  region                              = local.attacker_infrastructure_config.context.azure.region
  cluster_name                        = local.attacker_infrastructure_config.context.gcp.gke.cluster_name
  cluster_resource_group              = module.attacker-resource-group.resource_group 

  authorized_ip_ranges                = [
    module.workstation-external-ip.cidr
  ]
}

##################################################
# RUNBOOK
##################################################

module "attacker-runbook-deploy-lacework" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.runbook.deploy_lacework_agent.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-agent"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-compute[0].resource_group
  automation_account = module.attacker-automation-account[0].automation_account_name
  automation_princial_id = module.attacker-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework"

  lacework_agent_access_token = local.attacker_infrastructure_config.context.lacework.agent.token
  lacework_server_url         = local.attacker_infrastructure_config.context.lacework.server_url
  
  depends_on = [
    module.attacker-compute,
    module.attacker-automation-account
  ]

  providers = {
    azurerm = azurerm.attacker
    lacework = lacework.attacker
  }
}

module "attacker-runbook-deploy-lacework-syscall-config" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.runbook.deploy_lacework_syscall_config.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-syscall-config"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-compute[0].resource_group
  automation_account = module.attacker-automation-account[0].automation_account_name
  automation_princial_id = module.attacker-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_syscall"

  syscall_config = var.attacker_lacework_sysconfig_path
  
  depends_on = [
    module.attacker-compute,
    module.attacker-automation-account
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}

module "attacker-runbook-deploy-lacework-code-aware-agent" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.runbook.deploy_lacework_code_aware_agent.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-code-aware-agent"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-compute[0].resource_group
  automation_account = module.attacker-automation-account[0].automation_account_name
  automation_princial_id = module.attacker-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_code_aware_agent"
  
  depends_on = [
    module.attacker-compute,
    module.attacker-automation-account
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}

module "attacker-runbook-deploy-docker" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.runbook.deploy_docker.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-docker"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-compute[0].resource_group
  automation_account = module.attacker-automation-account[0].automation_account_name
  automation_princial_id = module.attacker-automation-account[0].automation_princial_id

  docker_users = local.attacker_infrastructure_config.context.azure.runbook.deploy_docker.docker_users

  tag             = "runbook_deploy_docker"
  
  depends_on = [
    module.attacker-compute,
    module.attacker-automation-account
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}

module "attacker-runbook-deploy-git" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.runbook.deploy_git.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-git"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-compute[0].resource_group
  automation_account = module.attacker-automation-account[0].automation_account_name
  automation_princial_id = module.attacker-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_git"
  
  depends_on = [
    module.attacker-compute,
    module.attacker-automation-account
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}

module "attacker-runbook-azure-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.runbook.deploy_azure_cli.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-azure-cli"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-compute[0].resource_group
  automation_account = module.attacker-automation-account[0].automation_account_name
  automation_princial_id = module.attacker-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_azure_cli"
  
  depends_on = [
    module.attacker-compute,
    module.attacker-automation-account
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}

module "attacker-runbook-lacework-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.runbook.deploy_lacework_cli.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-cli"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-compute[0].resource_group
  automation_account = module.attacker-automation-account[0].automation_account_name
  automation_princial_id = module.attacker-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_cli"
  
  depends_on = [
    module.attacker-compute,
    module.attacker-automation-account
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}

module "attacker-runbook-kubectl-cli" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.runbook.deploy_kubectl_cli.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-kubectl-cli"
  environment     = local.attacker_infrastructure_config.context.global.environment
  deployment      = local.attacker_infrastructure_config.context.global.deployment
  region          = local.attacker_infrastructure_config.context.azure.region
  resource_group  = module.attacker-compute[0].resource_group
  automation_account = module.attacker-automation-account[0].automation_account_name
  automation_princial_id = module.attacker-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_kubectl_cli"
  
  depends_on = [
    module.attacker-compute,
    module.attacker-automation-account
  ]

  providers = {
    azurerm = azurerm.attacker
  }
}



##################################################
# DYNU
##################################################

# locals {
#   records = [
#     for gce in can(length(module.attacker-gce)) ? module.attacker-gce : [] :
#     [
#       for compute in gce.instances : {
#         recordType     = "a"
#         recordName     = "${lookup(compute.instance.labels, "name", "unknown")}"
#         recordHostName = "${lookup(compute.instance.labels, "name", "unknown")}.${coalesce(local.attacker_infrastructure_config.context.dynu_dns.dns_domain, "unknown")}"
#         recordValue    = compute.instance.network_interface[0].access_config[0].nat_ip
#       } if lookup(try(compute.instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
#     ]
#   ]
# }

# module "attacker-dns-records" {
#   count           = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.dynu_dns.enabled == true  ) ? 1 : 0
#   source          = "../dynu/dns_records"
#   dynu_api_key  = local.attacker_infrastructure_config.context.dynu_dns.api_key
#   dynu_dns_domain = local.attacker_infrastructure_config.context.dynu_dns.dns_domain
#   records         = local.records
# }

##################################################
# AZURE Lacework
##################################################

# lacework cloud audit and config collection
module "attacker-lacework-audit-config" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.lacework.azure_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/lacework-audit-config"
  environment = local.attacker_infrastructure_config.context.global.environment
  deployment   = local.attacker_infrastructure_config.context.global.deployment

  providers = {
    azurerm = azurerm.attacker
    lacework = lacework.attacker
  }
}

# lacework agentless scanning
module "attacker-lacework-agentless" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.lacework.azure_agentless.enabled == true ) ? 1 : 0
  source      = "./modules/lacework-agentless"
  environment = local.attacker_infrastructure_config.context.global.environment
  deployment  = local.attacker_infrastructure_config.context.global.deployment
  region      = local.attacker_infrastructure_config.context.azure.region

  depends_on = [
    module.attacker-lacework-audit-config,
    module.attacker-compute
  ]

  providers = {
    lacework  = lacework.attacker
    azurerm   = azurerm.attacker
    azapi     = azapi.attacker
  }
}

##################################################
# AZURE AKS Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "attacker-lacework-daemonset" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.aks.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/lacework-kubernetes-daemonset"
  cluster_name                          = "${local.attacker_infrastructure_config.context.azure.aks.cluster_name}-${local.attacker_infrastructure_config.context.global.environment}-${local.attacker_infrastructure_config.context.global.deployment}"
  environment                           = local.attacker_infrastructure_config.context.global.environment
  deployment                            = local.attacker_infrastructure_config.context.global.deployment
  
  lacework_agent_access_token           = local.attacker_infrastructure_config.context.lacework.agent.token
  lacework_server_url                   = local.attacker_infrastructure_config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = false
  lacework_cluster_agent_cluster_region = local.attacker_infrastructure_config.context.azure.region

  syscall_config =  file(local.attacker_infrastructure_config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    lacework = lacework.attacker
  }

  depends_on = [
    module.attacker-aks
  ]
}

# lacework kubernetes admission controller
module "attacker-lacework-admission-controller" {
  count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.aks.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/lacework-kubernetes-admission-controller"
  environment           = local.attacker_infrastructure_config.context.global.environment
  deployment            = local.attacker_infrastructure_config.context.global.deployment
  
  lacework_account_name = local.attacker_infrastructure_config.context.lacework.account_name
  lacework_proxy_token  = local.attacker_infrastructure_config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.attacker
    helm = helm.attacker
    lacework  = lacework.attacker
  }

  depends_on = [
    module.attacker-aks
  ]
}

# lacework aks audit
# module "attacker-lacework-aks-audit" {
#   count = (local.attacker_infrastructure_config.context.global.enable_all == true) || (local.attacker_infrastructure_config.context.global.disable_all != true && local.attacker_infrastructure_config.context.azure.aks.enabled == true && local.attacker_infrastructure_config.context.lacework.agent.kubernetes.aks_audit_logs.enabled == true  ) ? 1 : 0
#   source                              = "./modules/aks-audit"
#   environment                         = local.attacker_infrastructure_config.context.global.environment
#   deployment                          = local.attacker_infrastructure_config.context.global.deployment

#   gcp_project_id                      = local.attacker_infrastructure_config.context.aks.project_id
#   gcp_location                        = local.attacker_infrastructure_config.context.aks.region

#   providers = {
#     kubernetes = kubernetes.main
#     helm = helm.main
#   }

#   depends_on = [
#     module.attacker-aks
#   ]
# }