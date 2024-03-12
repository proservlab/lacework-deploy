##################################################
# LOCALS
##################################################

locals {
  target_infrastructure_config                = var.target_infrastructure_config
  target_kubeconfig                           = pathexpand("~/.kube/azure-target-${local.target_infrastructure_config.context.global.deployment}-kubeconfig")
  target_cluster_name                         = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster.id : null
  target_cluster_endpoint                     = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster.endpoint : null
  target_cluster_ca_cert                      = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster.certificate_authority[0].data : null
  target_cluster_oidc_issuer                  = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster.identity[0].oidc[0].issuer : null
  target_cluster_security_group               = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster_sg_id : null
  target_cluster_vpc_id                       = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster_vpc_id : null
  target_cluster_vpc_subnet                   = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster_vpc_subnet : null
  target_cluster_openid_connect_provider_arn  = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster_openid_connect_provider.arn : null
  target_cluster_openid_connect_provider_url  = local.target_infrastructure_config.context.azure.aks.enabled ? module.target-aks[0].cluster_openid_connect_provider.url : null
  target_tenant_id                            = var.target_azure_tenant
  target_subscription_id                      = var.target_azure_subscription
}

##################################################
# AZURE RUNBOOK SIMULATION
##################################################

module "target-automation-account" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  source          = "./modules/automation/account"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-resource-group.resource_group

  depends_on = [
    module.target-compute,
    module.target-resource-group
  ]

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# AZURE Resource Group
##################################################

module "target-resource-group" {
  source = "./modules/resource-group"
  name = "resource-group"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
  region       = local.target_infrastructure_config.context.azure.region

  providers = {
    azurerm = azurerm.target
  }
}

# module "target-resource-group-app" {
#   source = "./modules/resource-group"
#   name = "resource-group-app"
#   environment  = local.target_infrastructure_config.context.global.environment
#   deployment   = local.target_infrastructure_config.context.global.deployment
#   region       = local.target_infrastructure_config.context.azure.region

#   providers = {
#     azurerm = azurerm.target
#   }
# }

##################################################
# AZURE COMPUTE
##################################################

# compute
module "target-compute" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.compute.enabled == true ) ? 1 : 0
  source       = "./modules/compute"
  environment  = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment
  region       = local.target_infrastructure_config.context.azure.region
  
  # list of instances to configure
  instances = local.target_infrastructure_config.context.azure.compute.instances

  # allow endpoints inside their own security group to communicate
  trust_security_group = local.target_infrastructure_config.context.global.trust_security_group

  public_ingress_rules = local.target_infrastructure_config.context.azure.compute.public_ingress_rules
  public_egress_rules = local.target_infrastructure_config.context.azure.compute.public_egress_rules
  public_app_ingress_rules = local.target_infrastructure_config.context.azure.compute.public_app_ingress_rules
  public_app_egress_rules = local.target_infrastructure_config.context.azure.compute.public_app_egress_rules
  private_ingress_rules = local.target_infrastructure_config.context.azure.compute.private_ingress_rules
  private_egress_rules = local.target_infrastructure_config.context.azure.compute.private_egress_rules
  private_app_ingress_rules = local.target_infrastructure_config.context.azure.compute.private_app_ingress_rules
  private_app_egress_rules = local.target_infrastructure_config.context.azure.compute.private_app_egress_rules

  public_network = local.target_infrastructure_config.context.azure.compute.public_network
  public_subnet = local.target_infrastructure_config.context.azure.compute.public_subnet
  public_app_network = local.target_infrastructure_config.context.azure.compute.public_app_network
  public_app_subnet = local.target_infrastructure_config.context.azure.compute.public_app_subnet
  private_network = local.target_infrastructure_config.context.azure.compute.private_network
  private_subnet = local.target_infrastructure_config.context.azure.compute.private_subnet
  private_nat_subnet = local.target_infrastructure_config.context.azure.compute.private_nat_subnet
  private_app_network = local.target_infrastructure_config.context.azure.compute.private_app_network
  private_app_subnet = local.target_infrastructure_config.context.azure.compute.private_app_subnet
  private_app_nat_subnet = local.target_infrastructure_config.context.azure.compute.private_app_nat_subnet

  resource_group = module.target-resource-group.resource_group
  resource_app_group = module.target-resource-group.resource_group

  enable_dynu_dns                     = local.target_infrastructure_config.context.dynu_dns.enabled
  dynu_dns_domain                     = local.target_infrastructure_config.context.dynu_dns.dns_domain
  dynu_api_key                        = local.target_infrastructure_config.context.dynu_dns.api_key

  depends_on = [
    module.target-resource-group,
    module.target-resource-group
  ]

  providers = {
    azurerm = azurerm.target
    restapi = restapi.main
  }
}

##################################################
# AZURE SQL
##################################################

module "target-azuresql" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.azuresql.enabled == true ) ? 1 : 0
  source                              = "./modules/azuresql"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment
  region                              = local.target_infrastructure_config.context.azure.region
  server_name                         = local.target_infrastructure_config.context.azure.azuresql.server_name
  db_name                             = local.target_infrastructure_config.context.azure.azuresql.db_name
  db_resource_group_name              = module.target-resource-group.resource_group.name
  db_virtual_network_name             = module.target-compute[0].public_app_virtual_network.name
  db_virtual_network_id               = module.target-compute[0].public_app_virtual_network.id
  db_subnet_network                   = [cidrsubnet(local.target_infrastructure_config.context.azure.compute.public_app_network,8,200)]

  instance_type                       = local.target_infrastructure_config.context.azure.azuresql.instance_type
  sku_name                            = local.target_infrastructure_config.context.azure.azuresql.sku_name
  public_network_access_enabled       = local.target_infrastructure_config.context.azure.azuresql.public_network_access_enabled

  # authorized_ip_ranges                = [module.target-workstation-external-ip.cidr]

  depends_on = [ module.target-compute ]

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# AZURE SQL
##################################################

module "target-azurestorage" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.azurestorage.enabled == true ) ? 1 : 0
  source                              = "./modules/azurestorage"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment
  region                              = local.target_infrastructure_config.context.azure.region
  storage_resource_group_name         = module.target-resource-group.resource_group.name
  storage_virtual_network_name        = module.target-compute[0].public_app_virtual_network.name
  storage_virtual_network_id          = module.target-compute[0].public_app_virtual_network.id
  storage_subnet_network              = [cidrsubnet(local.target_infrastructure_config.context.azure.compute.public_app_network,8,201)]

  account_replication_type            = local.target_infrastructure_config.context.azure.azurestorage.account_replication_type
  account_tier                        = local.target_infrastructure_config.context.azure.azurestorage.account_tier
  public_network_access_enabled       = local.target_infrastructure_config.context.azure.azurestorage.public_network_access_enabled
  
  # add the local workstation and all public addresses for compute instances
  trusted_networks                    = flatten([
    [ replace(module.workstation-external-ip.cidr,"/32","") ],
    [ for instance in try(module.target-compute[0].instances, []): replace(instance.public_ip,"/32","") if instance.role == "app" && instance.public == "true"],
    [ for instance in try(module.target-compute[0].instances, []): replace(instance.public_ip,"/32","") if instance.role == "default" && instance.public == "true"]
  ])

  depends_on = [ module.target-compute ]

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# AZURE AKS
##################################################

module "target-aks" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.aks.enabled == true ) ? 1 : 0
  source                              = "./modules/aks"
  environment                         = local.target_infrastructure_config.context.global.environment
  deployment                          = local.target_infrastructure_config.context.global.deployment
  region                              = local.target_infrastructure_config.context.azure.region
  cluster_name                        = local.target_infrastructure_config.context.gcp.gke.cluster_name
  cluster_resource_group              = module.target-resource-group.resource_group 

  authorized_ip_ranges                = [
    module.workstation-external-ip.cidr
  ]

  providers = {
    azurerm = azurerm.target
  }
}

##################################################
# RUNBOOK
##################################################

module "target-runbook-deploy-lacework" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.runbook.deploy_lacework_agent.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-agent"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-compute[0].resource_group
  automation_account = module.target-automation-account[0].automation_account_name
  automation_princial_id = module.target-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework"

  lacework_agent_access_token = local.target_infrastructure_config.context.lacework.agent.token
  lacework_server_url         = local.target_infrastructure_config.context.lacework.server_url
  
  depends_on = [
    module.target-compute,
    module.target-automation-account
  ]

  providers = {
    azurerm = azurerm.target
    lacework = lacework.target
  }
}

module "target-runbook-deploy-lacework-syscall-config" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.runbook.deploy_lacework_syscall_config.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-syscall-config"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-compute[0].resource_group
  automation_account = module.target-automation-account[0].automation_account_name
  automation_princial_id = module.target-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_syscall"

  syscall_config = var.target_lacework_sysconfig_path
  
  depends_on = [
    module.target-compute,
    module.target-automation-account
  ]

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-deploy-lacework-code-aware-agent" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.runbook.deploy_lacework_code_aware_agent.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-code-aware-agent"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-compute[0].resource_group
  automation_account = module.target-automation-account[0].automation_account_name
  automation_princial_id = module.target-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_code_aware_agent"
  
  depends_on = [
    module.target-compute,
    module.target-automation-account
  ]

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-deploy-docker" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.runbook.deploy_docker.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-docker"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-compute[0].resource_group
  automation_account = module.target-automation-account[0].automation_account_name
  automation_princial_id = module.target-automation-account[0].automation_princial_id

  docker_users = local.target_infrastructure_config.context.azure.runbook.deploy_docker.docker_users

  tag             = "runbook_deploy_docker"
  
  depends_on = [
    module.target-compute,
    module.target-automation-account
  ]

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-deploy-git" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.runbook.deploy_git.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-git"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-compute[0].resource_group
  automation_account = module.target-automation-account[0].automation_account_name
  automation_princial_id = module.target-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_git"
  
  depends_on = [
    module.target-compute,
    module.target-automation-account
  ]

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-azure-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.runbook.deploy_azure_cli.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-azure-cli"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-compute[0].resource_group
  automation_account = module.target-automation-account[0].automation_account_name
  automation_princial_id = module.target-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_azure_cli"
  
  depends_on = [
    module.target-compute,
    module.target-automation-account
  ]

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-lacework-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.runbook.deploy_lacework_cli.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-cli"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-compute[0].resource_group
  automation_account = module.target-automation-account[0].automation_account_name
  automation_princial_id = module.target-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_cli"
  
  depends_on = [
    module.target-compute,
    module.target-automation-account
  ]

  providers = {
    azurerm = azurerm.target
  }
}

module "target-runbook-kubectl-cli" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.runbook.deploy_kubectl_cli.enabled == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-kubectl-cli"
  environment     = local.target_infrastructure_config.context.global.environment
  deployment      = local.target_infrastructure_config.context.global.deployment
  region          = local.target_infrastructure_config.context.azure.region
  resource_group  = module.target-compute[0].resource_group
  automation_account = module.target-automation-account[0].automation_account_name
  automation_princial_id = module.target-automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_kubectl_cli"
  
  depends_on = [
    module.target-compute,
    module.target-automation-account
  ]

  providers = {
    azurerm = azurerm.target
  }
}



##################################################
# DYNU
##################################################

# locals {
#   records = [
#     for gce in can(length(module.target-gce)) ? module.target-gce : [] :
#     [
#       for compute in gce.instances : {
#         recordType     = "a"
#         recordName     = "${lookup(compute.instance.labels, "name", "unknown")}"
#         recordHostName = "${lookup(compute.instance.labels, "name", "unknown")}.${coalesce(local.target_infrastructure_config.context.dynu_dns.dns_domain, "unknown")}"
#         recordValue    = compute.instance.network_interface[0].access_config[0].nat_ip
#       } if lookup(try(compute.instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
#     ]
#   ]
# }

# module "target-dns-records" {
#   count           = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.dynu_dns.enabled == true  ) ? 1 : 0
#   source          = "../dynu/dns_records"
#   dynu_api_key  = local.target_infrastructure_config.context.dynu_dns.api_key
#   dynu_dns_domain = local.target_infrastructure_config.context.dynu_dns.dns_domain
#   records         = local.records
# }

##################################################
# AZURE Lacework
##################################################

# lacework cloud audit and config collection
module "target-lacework-audit-config" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.lacework.azure_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/lacework-audit-config"
  environment = local.target_infrastructure_config.context.global.environment
  deployment   = local.target_infrastructure_config.context.global.deployment

  providers = {
    azurerm = azurerm.target
    lacework = lacework.target
  }
}

# lacework agentless scanning
module "target-lacework-agentless" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.lacework.azure_agentless.enabled == true ) ? 1 : 0
  source      = "./modules/lacework-agentless"
  environment = local.target_infrastructure_config.context.global.environment
  deployment  = local.target_infrastructure_config.context.global.deployment
  region      = local.target_infrastructure_config.context.azure.region

  depends_on = [
    module.target-lacework-audit-config,
    module.target-compute
  ]

  providers = {
    lacework  = lacework.target
    azurerm   = azurerm.target
  }
}

##################################################
# AZURE AKS Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "target-lacework-daemonset" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.aks.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/lacework-kubernetes-daemonset"
  cluster_name                          = "${local.target_infrastructure_config.context.azure.aks.cluster_name}-${local.target_infrastructure_config.context.global.environment}-${local.target_infrastructure_config.context.global.deployment}"
  environment                           = local.target_infrastructure_config.context.global.environment
  deployment                            = local.target_infrastructure_config.context.global.deployment
  
  lacework_agent_access_token           = local.target_infrastructure_config.context.lacework.agent.token
  lacework_server_url                   = local.target_infrastructure_config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = false
  lacework_cluster_agent_cluster_region = local.target_infrastructure_config.context.azure.region

  syscall_config =  file(local.target_infrastructure_config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-aks
  ]
}

# lacework kubernetes admission controller
module "target-lacework-admission-controller" {
  count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.aks.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/lacework-kubernetes-admission-controller"
  environment           = local.target_infrastructure_config.context.global.environment
  deployment            = local.target_infrastructure_config.context.global.deployment
  
  lacework_account_name = local.target_infrastructure_config.context.lacework.account_name
  lacework_proxy_token  = local.target_infrastructure_config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    lacework = lacework.target
  }

  depends_on = [
    module.target-aks
  ]
}

# lacework aks audit
# module "target-lacework-aks-audit" {
#   count = (local.target_infrastructure_config.context.global.enable_all == true) || (local.target_infrastructure_config.context.global.disable_all != true && local.target_infrastructure_config.context.azure.aks.enabled == true && local.target_infrastructure_config.context.lacework.agent.kubernetes.aks_audit_logs.enabled == true  ) ? 1 : 0
#   source                              = "./modules/aks-audit"
#   environment                         = local.target_infrastructure_config.context.global.environment
#   deployment                          = local.target_infrastructure_config.context.global.deployment

#   gcp_project_id                      = local.target_infrastructure_config.context.aks.project_id
#   gcp_location                        = local.target_infrastructure_config.context.aks.region

#   providers = {
#     kubernetes = kubernetes.main
#     helm = helm.main
#   }

#   depends_on = [
#     module.target-aks
#   ]
# }