data "google_compute_zones" "this" {
    region = var.gcp_location
}

locals {
  public_compute_instances = var.enable_dynu_dns == true ? flatten([
    [ for compute in module.instances: compute.instance if compute.instance.labels.role == "default" && compute.instance.labels.public == "true" ],
    [ for compute in module.instances: compute.instance if compute.instance.labels.role == "app" && compute.instance.labels.public == "true" ]
  ]) : []
  
  public_instance_count = length([ for instance in var.instances: instance if instance.public == true ])
  public_app_instance_count = length([ for instance in var.instances: instance if instance.public == true && instance.role == "app" ])
  private_instance_count = length([ for instance in var.instances: instance if instance.public == false ])
  private_app_instance_count = length([ for instance in var.instances: instance if instance.public == false && instance.role == "app" ])
}

# default tags
module "default-osconfig-tags" {
  source = "../../../../context/tags"
}

# lookup latest amis
module "amis" {
  source = "./amis"
}

module "public_service_account" {
  source = "./service_account"
  environment = var.environment
  deployment = var.deployment
  gcp_location  = var.gcp_location
  gcp_project_id  = var.gcp_project_id
  name = "public-sa"
}

module "public_app_service_account" {
  source = "./service_account"
  environment = var.environment
  deployment = var.deployment
  gcp_location  = var.gcp_location
  gcp_project_id  = var.gcp_project_id
  name = "public-app-sa"
}

module "private_service_account" {
  source = "./service_account"
  environment = var.environment
  deployment = var.deployment
  gcp_location  = var.gcp_location
  gcp_project_id  = var.gcp_project_id
  name = "private-sa"
}

module "private_app_service_account" {
  source = "./service_account"
  environment = var.environment
  deployment = var.deployment
  gcp_location  = var.gcp_location
  gcp_project_id  = var.gcp_project_id
  name = "private-app-sa"
}

# build private and public vpcs
module "vpc" {
  source = "./vpc"
  name = "${var.environment}-${var.deployment}"
  environment = var.environment
  deployment = var.deployment
  gcp_location  = var.gcp_location
  gcp_project_id  = var.gcp_project_id

  enable_public_vpc = local.public_instance_count > 0 ? true : false
  enable_public_app_vpc = local.public_app_instance_count > 0 ? true : false
  enable_private_vpc = local.private_instance_count > 0 ? true : false
  enable_private_app_vpc = local.private_app_instance_count > 0 ? true : false

  private_ingress_rules = var.private_ingress_rules
  private_egress_rules = var.private_egress_rules
  public_ingress_rules = var.public_ingress_rules
  public_egress_rules = var.public_egress_rules
  trust_security_group=var.trust_security_group

  public_network = var.public_network
  public_subnet = var.public_subnet
  public_app_network = var.public_app_network
  public_app_subnet = var.public_app_subnet
  private_network = var.private_network
  private_subnet = var.private_subnet
  private_nat_subnet = var.private_nat_subnet
  private_app_network = var.private_network
  private_app_subnet = var.private_subnet
  private_app_nat_subnet = var.private_nat_subnet

  public_service_account_email =  module.public_service_account.service_account_email
  public_app_service_account_email =  module.public_app_service_account.service_account_email
  private_service_account_email =  module.private_service_account.service_account_email
  private_app_service_account_email =  module.private_app_service_account.service_account_email
}

# instances
module "instances" {
  for_each = { for instance in var.instances: instance.name => instance }
  source = "./instance"
  environment = var.environment
  deployment = var.deployment
  gcp_location  = var.gcp_location
  gcp_project_id  = var.gcp_project_id
  
  name          = "${lookup(each.value, "name", "default-name")}-${var.environment}-${var.deployment}"
  public        = lookup(each.value, "public", true)
  role          = lookup(each.value, "role", "default")
  instance_type                   = lookup(each.value, "instance_type", "e2-micro")
  enable_secondary_volume         = lookup(each.value, "enable_secondary_volume", false)
  enable_swap                     = lookup(each.value, "enable_swap", true)
  ami                             = module.amis.ami_map[lookup(each.value, "ami_name", "ubuntu_focal")]
  user_data                       = lookup(each.value, "user_data", null)
  user_data_base64                = lookup(each.value, "user_data_base64", null)
  
  # iam_instance_profile = each.value.role == "app" ? module.ssm_app_profile.ec2-iam-profile.name : module.ssm_profile.ec2-iam-profile.name
  
  subnet_id = each.value.public == true ? (each.value.role == "app" ? module.vpc.public_app_subnetwork.name : module.vpc.public_subnetwork.name ) : (each.value.role == "app" ? module.vpc.private_app_subnetwork.name : module.vpc.private_subnetwork.name )
  # vpc_security_group_ids = [ each.value.public == true ? (each.value.role == "app" ? module.vpc.public_app_sg.id : module.vpc.public_sg.id ) : (each.value.role == "app" ? module.vpc.private_app_sg.id : module.vpc.private_sg.id ) ]

  # merge additional tags including ssm deployment tag
  tags = merge(
    module.default-osconfig-tags.osconfig_default_tags,
    merge(
      {
        Name = "${each.value.name}-${var.environment}-${var.deployment}"
        environment = var.environment
        deployment = var.deployment
        public = each.value.public
        role = each.value.role
      },
      each.value.tags,
    )
  )

  public_service_account_email =  module.public_service_account.service_account_email
  public_app_service_account_email =  module.public_app_service_account.service_account_email
  private_service_account_email =  module.private_service_account.service_account_email
  private_app_service_account_email =  module.private_app_service_account.service_account_email
}

locals {
  public_instances = [ for compute in module.instances: compute.instance.self_link if compute.instance.labels.role == "default" && compute.instance.labels.public == "true" ]
  public_app_instances = [ for compute in module.instances: compute.instance.self_link if compute.instance.labels.role == "app" && compute.instance.labels.public == "true" ]
  private_instances = [ for compute in module.instances: compute.instance.self_link if compute.instance.labels.role == "default" && compute.instance.labels.public == "false" ]
  private_app_instances = [ for compute in module.instances: compute.instance.self_link if compute.instance.labels.role == "app" && compute.instance.labels.public == "false" ]
}

module "dns-records" {
  count           = length(local.public_compute_instances)
  source          = "../../../dynu/dns_record"
  dynu_dns_domain = var.dynu_dns_domain
  
  record        = {
        recordType     = "A"
        recordName     = "${lookup(local.public_compute_instances[count.index].labels, "name", "unknown")}"
        recordHostName = "${lookup(local.public_compute_instances[count.index].labels, "name", "unknown")}.${coalesce(var.dynu_dns_domain, "unknown")}"
        recordValue    = local.public_compute_instances[count.index].network_interface[0].access_config[0].nat_ip
      }
}

resource "google_compute_instance_group" "public_group" {
  count       = local.public_instance_count > 0 ? 1 : 0
  name        = "${var.environment}-${var.deployment}-public-default-group"
  description = "${var.environment}-${var.deployment}-public-default-group instance group"
  zone        = data.google_compute_zones.this.names[0]
  network     = module.vpc.public_network.id
  instances   = local.public_instances
}

resource "google_compute_instance_group" "public_app_group" {
  count       = local.public_app_instance_count > 0 ? 1 : 0
  name        = "${var.environment}-${var.deployment}-public-app-group"
  description = "${var.environment}-${var.deployment}-public-app-group instance group"
  zone        = data.google_compute_zones.this.names[0]
  network     = module.vpc.public_app_network.id
  instances   = local.public_app_instances
}

resource "google_compute_instance_group" "private_group" {
  count       = local.private_instance_count > 0 ? 1 : 0
  name        = "${var.environment}-${var.deployment}-private-default-group"
  description = "${var.environment}-${var.deployment}-private-default-group instance group"
  zone        = data.google_compute_zones.this.names[0]
  network     = module.vpc.private_network.id
  instances   = local.private_instances
}

resource "google_compute_instance_group" "private_app_group" {
  count       = local.private_app_instance_count > 0 ? 1 : 0
  name        = "${var.environment}-${var.deployment}-private-app-group"
  description = "${var.environment}-${var.deployment}-private-app-group instance group"
  zone        = data.google_compute_zones.this.names[0]
  network     = module.vpc.private_app_network.id
  instances   = local.private_app_instances
}