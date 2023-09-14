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

resource "null_resource" "log" {
  triggers = {
    log_message = jsonencode(local.config)
  }

  provisioner "local-exec" {
    command = "echo '${jsonencode(local.config)}'"
  }
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

  depends_on = [
    module.resource-group
  ]
}

##################################################
# RUBOOK
##################################################

module "runbook-deploy-lacework" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_lacework_agent == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework"
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
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_lacework_syscall_config == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-syscall-config"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_lacework_syscall"

  syscall_config = "${path.module}/modules/runbook/deploy-lacework-syscall-config/resources/syscall_config.yaml"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-deploy-lacework-code-aware-agent" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_lacework_code_aware_agent == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-code-aware-agent"
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
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_docker == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-docker"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_docker"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-deploy-git" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_git == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-git"
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

module "runbook-aws-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_aws_cli == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-aws-cli"
  environment     = local.config.context.global.environment
  deployment      = local.config.context.global.deployment
  region          = local.config.context.azure.region
  resource_group  = module.compute[0].resource_group
  automation_account = module.automation-account[0].automation_account_name
  automation_princial_id = module.automation-account[0].automation_princial_id
  
  tag             = "runbook_deploy_aws_cli"
  
  depends_on = [
    module.compute,
    module.automation-account
  ]
}

module "runbook-lacework-cli" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_lacework_cli == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-lacework-cli"
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
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.azure.runbook.deploy_kubectl_cli == true ) ? 1 : 0
  source          = "./modules/runbook/deploy-kubectl-cli"
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