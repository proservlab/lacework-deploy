##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../context/deployment"
}

##################################################
# LOCALS
##################################################

locals {
  config = var.config
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

##################################################
# AZURE COMPUTE
##################################################

# compute
module "compute" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.azure.compute.enabled == true && can(length(var.config.context.azure.compute.instances))) ? 1 : 0
  source       = "./modules/compute"
  environment  = var.config.context.global.environment
  deployment   = var.config.context.global.deployment
  region       = var.config.context.azure.region
  
  # list of instances to configure
  instances = var.config.context.azure.compute.instances

  # allow endpoints inside their own security group to communicate
  trust_security_group = var.config.context.global.trust_security_group

  public_ingress_rules = var.config.context.azure.compute.public_ingress_rules
  public_egress_rules = var.config.context.azure.compute.public_egress_rules
  public_app_ingress_rules = var.config.context.azure.compute.public_app_ingress_rules
  public_app_egress_rules = var.config.context.azure.compute.public_app_egress_rules
  private_ingress_rules = var.config.context.azure.compute.private_ingress_rules
  private_egress_rules = var.config.context.azure.compute.private_egress_rules
  private_app_ingress_rules = var.config.context.azure.compute.private_app_ingress_rules
  private_app_egress_rules = var.config.context.azure.compute.private_app_egress_rules

  public_network = var.config.context.azure.compute.public_network
  public_subnet = var.config.context.azure.compute.public_subnet
  public_app_network = var.config.context.azure.compute.public_app_network
  public_app_subnet = var.config.context.azure.compute.public_app_subnet
  private_network = var.config.context.azure.compute.private_network
  private_subnet = var.config.context.azure.compute.private_subnet
  private_nat_subnet = var.config.context.azure.compute.private_nat_subnet
  private_app_network = var.config.context.azure.compute.private_app_network
  private_app_subnet = var.config.context.azure.compute.private_app_subnet
  private_app_nat_subnet = var.config.context.azure.compute.private_app_nat_subnet
}
