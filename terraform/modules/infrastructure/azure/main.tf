##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../context/deployment"
}

##################################################
# LOCALS
##################################################

module "default-config" {
  source = "../../context/infrastructure"
}

locals {
  config = try(length(var.config), {}) == {} ? module.default-config.config : var.config
}



##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AZURE RUNBOOK SIMULATION
##################################################

module "automation-account" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.enabled == true ) ? 1 : 0
  source          = "./modules/automation/account"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.resource-group.resource_group

  depends_on = [
    module.compute,
    module.resource-group
  ]
}

##################################################
# AZURE Resource Group
##################################################

module "resource-group" {
  source = "./modules/resource-group"
  name = "resource-group"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.azure.region
}

module "resource-group-app" {
  source = "./modules/resource-group"
  name = "resource-group-app"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.azure.region
}

##################################################
# AZURE COMPUTE
##################################################

# compute
module "compute" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.compute.enabled == true ) ? 1 : 0
  source       = "./modules/compute"
  environment  = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
  region       = local.config.context.azure.region
  
  # list of instances to configure
  instances = local.config.context.azure.compute.instances

  # allow endpoints inside their own security group to communicate
  trust_security_group = local.config.context.global.trust_security_group

  public_ingress_rules = local.config.context.azure.compute.public_ingress_rules
  public_egress_rules = local.config.context.azure.compute.public_egress_rules
  public_app_ingress_rules = local.config.context.azure.compute.public_app_ingress_rules
  public_app_egress_rules = local.config.context.azure.compute.public_app_egress_rules
  private_ingress_rules = local.config.context.azure.compute.private_ingress_rules
  private_egress_rules = local.config.context.azure.compute.private_egress_rules
  private_app_ingress_rules = local.config.context.azure.compute.private_app_ingress_rules
  private_app_egress_rules = local.config.context.azure.compute.private_app_egress_rules

  public_network = local.config.context.azure.compute.public_network
  public_subnet = local.config.context.azure.compute.public_subnet
  public_app_network = local.config.context.azure.compute.public_app_network
  public_app_subnet = local.config.context.azure.compute.public_app_subnet
  private_network = local.config.context.azure.compute.private_network
  private_subnet = local.config.context.azure.compute.private_subnet
  private_nat_subnet = local.config.context.azure.compute.private_nat_subnet
  private_app_network = local.config.context.azure.compute.private_app_network
  private_app_subnet = local.config.context.azure.compute.private_app_subnet
  private_app_nat_subnet = local.config.context.azure.compute.private_app_nat_subnet

  resource_group = module.resource-group.resource_group
  resource_app_group = module.resource-group-app.resource_group

  depends_on = [
    module.resource-group,
    module.resource-group-app
  ]
}

##################################################
# AZURE SQL
##################################################

module "azuresql" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.azuresql.enabled == true ) ? 1 : 0
  source                              = "./modules/azuresql"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  region                              = local.config.context.azure.region
  server_name                         = local.config.context.azure.azuresql.server_name
  db_name                             = local.config.context.azure.azuresql.db_name
  db_resource_group_name              = module.resource-group-app.resource_group.name
  db_virtual_network_name             = module.compute[0].public_app_virtual_network.name
  db_virtual_network_id               = module.compute[0].public_app_virtual_network.id
  db_subnet_network                   = [cidrsubnet(local.config.context.azure.compute.public_app_network,8,200)]

  instance_type                       = local.config.context.azure.azuresql.instance_type
  sku_name                            = local.config.context.azure.azuresql.sku_name
  public_network_access_enabled       = local.config.context.azure.azuresql.public_network_access_enabled

  # authorized_ip_ranges                = [module.workstation-external-ip.cidr]

  depends_on = [ module.compute ]
}

##################################################
# AZURE SQL
##################################################

module "azurestorage" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.azurestorage.enabled == true ) ? 1 : 0
  source                              = "./modules/azurestorage"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  region                              = local.config.context.azure.region
  storage_resource_group_name         = module.resource-group-app.resource_group.name
  storage_virtual_network_name        = module.compute[0].public_app_virtual_network.name
  storage_virtual_network_id          = module.compute[0].public_app_virtual_network.id
  storage_subnet_network              = [cidrsubnet(local.config.context.azure.compute.public_app_network,8,201)]

  account_replication_type            = local.config.context.azure.azurestorage.account_replication_type
  account_tier                        = local.config.context.azure.azurestorage.account_tier
  public_network_access_enabled       = local.config.context.azure.azurestorage.public_network_access_enabled
  
  # add the local workstation and all public addresses for compute instances
  trusted_networks                    = flatten([
    [ replace(module.workstation-external-ip.cidr,"/32","") ],
    [ for instance in try(module.compute[0].instances, []): replace(instance.public_ip,"/32","") if instance.role == "app" && instance.public == "true"],
    [ for instance in try(module.compute[0].instances, []): replace(instance.public_ip,"/32","") if instance.role == "default" && instance.public == "true"]
  ])

  depends_on = [ module.compute ]
}

##################################################
# AZURE AKS
##################################################

module "aks" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.aks.enabled == true ) ? 1 : 0
  source                              = "./modules/aks"
  environment                         = local.config.context.global.environment
  deployment                          = local.config.context.global.deployment
  region                              = local.config.context.azure.region
  cluster_name                        = local.config.context.gcp.gke.cluster_name
  cluster_resource_group              = module.resource-group.resource_group 

  authorized_ip_ranges                = [module.workstation-external-ip.cidr]
}

##################################################
# RUNBOOK
##################################################

module "runbook-deploy-lacework" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_lacework_agent.enabled == true ) ? 1 : 0
  source          = "../../attack/surface/azure/modules/runbook/deploy-lacework-agent"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework"

  lacework_agent_access_token = local.config.context.lacework.agent.token
  lacework_server_url         = local.config.context.lacework.server_url
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-deploy-lacework-syscall-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_lacework_syscall_config.enabled == true ) ? 1 : 0
  source          = "../../attack/surface/azure/modules/runbook/deploy-lacework-syscall-config"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_syscall"

  syscall_config = var.default_lacework_sysconfig_path
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-deploy-lacework-code-aware-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_lacework_code_aware_agent.enabled == true ) ? 1 : 0
  source          = "../../attack/surface/azure/modules/runbook/deploy-lacework-code-aware-agent"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_code_aware_agent"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-deploy-docker" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_docker.enabled == true ) ? 1 : 0
  source          = "../../attack/surface/azure/modules/runbook/deploy-docker"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id

  docker_users = local.config.context.azure.runbook.deploy_docker.docker_users

  tag             = "runbook_deploy_docker"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-deploy-git" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_git.enabled == true ) ? 1 : 0
  source          = "../../attack/surface/azure/modules/runbook/deploy-git"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_git"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-azure-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_azure_cli.enabled == true ) ? 1 : 0
  source          = "../../attack/surface/azure/modules/runbook/deploy-azure-cli"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_azure_cli"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-lacework-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_lacework_cli.enabled == true ) ? 1 : 0
  source          = "../../attack/surface/azure/modules/runbook/deploy-lacework-cli"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_cli"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-kubectl-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_kubectl_cli.enabled == true ) ? 1 : 0
  source          = "../../attack/surface/azure/modules/runbook/deploy-kubectl-cli"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_kubectl_cli"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}



##################################################
# DYNU
##################################################

# locals {
#   records = [
#     for gce in can(length(module.gce)) ? module.gce : [] :
#     [
#       for compute in gce.instances : {
#         recordType     = "a"
#         recordName     = "${lookup(compute.instance.labels, "name", "unknown")}"
#         recordHostName = "${lookup(compute.instance.labels, "name", "unknown")}.${coalesce(local.config.context.dynu_dns.dns_domain, "unknown")}"
#         recordValue    = compute.instance.network_interface[0].access_config[0].nat_ip
#       } if lookup(try(compute.instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false"
#     ]
#   ]
# }

# module "dns-records" {
#   count           = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.dynu_dns.enabled == true  ) ? 1 : 0
#   source          = "../dynu/dns_records"
#   dynu_api_key  = local.config.context.dynu_dns.api_key
#   dynu_dns_domain = local.config.context.dynu_dns.dns_domain
#   records         = local.records
# }

##################################################
# AZURE Lacework
##################################################

# lacework cloud audit and config collection
module "lacework-audit-config" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.azure_audit_config.enabled == true ) ? 1 : 0
  source      = "./modules/audit-config"
  environment = local.config.context.global.environment
  deployment   = local.config.context.global.deployment
}

# lacework agentless scanning
# module "lacework-agentless" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.lacework.aws_agentless.enabled == true ) ? 1 : 0
#   source      = "./modules/agentless"
#   environment = local.config.context.global.environment
#   deployment   = local.config.context.global.deployment
# }

##################################################
# AZURE AKS Lacework
##################################################

# lacework daemonset and kubernetes compliance
module "lacework-daemonset" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.aks.enabled == true && local.config.context.lacework.agent.kubernetes.daemonset.enabled == true  ) ? 1 : 0
  source                                = "./modules/kubernetes/daemonset"
  cluster_name                          = "${local.config.context.azure.aks.cluster_name}-${local.config.context.global.environment}-${local.config.context.global.deployment}"
  environment                           = local.config.context.global.environment
  deployment                            = local.config.context.global.deployment
  
  lacework_agent_access_token           = local.config.context.lacework.agent.token
  lacework_server_url                   = local.config.context.lacework.server_url
  
  # compliance cluster agent
  lacework_cluster_agent_enable         = false
  lacework_cluster_agent_cluster_region = local.config.context.azure.region

  syscall_config =  file(local.config.context.lacework.agent.kubernetes.daemonset.syscall_config_path)

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.aks
  ]
}

# lacework kubernetes admission controller
module "lacework-admission-controller" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.aks.enabled == true && local.config.context.lacework.agent.kubernetes.admission_controller.enabled == true  ) ? 1 : 0
  source                = "./modules/kubernetes/admission-controller"
  environment           = local.config.context.global.environment
  deployment            = local.config.context.global.deployment
  
  lacework_account_name = local.config.context.lacework.account_name
  lacework_proxy_token  = local.config.context.lacework.agent.kubernetes.proxy_scanner.token

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }

  depends_on = [
    module.aks
  ]
}

# lacework aks audit
# module "lacework-aks-audit" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.aks.enabled == true && local.config.context.lacework.agent.kubernetes.aks_audit_logs.enabled == true  ) ? 1 : 0
#   source                              = "./modules/aks-audit"
#   environment                         = local.config.context.global.environment
#   deployment                          = local.config.context.global.deployment

#   gcp_project_id                      = local.config.context.aks.project_id
#   gcp_location                        = local.config.context.aks.region

#   providers = {
#     kubernetes = kubernetes.main
#     helm = helm.main
#   }

#   depends_on = [
#     module.aks
#   ]
# }