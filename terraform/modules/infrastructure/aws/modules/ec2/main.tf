locals {
  public_compute_instances = var.enable_dynu_dns == true ? flatten([
    [ for ec2 in module.instances: ec2.instance if lookup(ec2.instance.tags, "public", "false") == "true" ]
  ]) : []
  public_instance_count = length([ for instance in var.instances: instance if instance.public == true ])
  public_app_instance_count = length([ for instance in var.instances: instance if instance.public == true && instance.role == "app" ])
  private_instance_count = length([ for instance in var.instances: instance if instance.public == false ])
  private_app_instance_count = length([ for instance in var.instances: instance if instance.public == false && instance.role == "app" ])
}

# default tags
module "default-ssm-tags" {
  source = "../../../../context/tags"
}

# lookup latest amis
module "amis" {
  source = "./amis"
}

# create an ssm iam instance profile
module "ssm_profile" {
  source = "./ssm-profile"
  role = "default"
  environment = var.environment
  deployment = var.deployment
}

module "ssm_app_profile" {
  source = "./ssm-profile"
  role = "app"
  environment = var.environment
  deployment = var.deployment
}

# build private and public vpcs
module "vpc" {
  source = "./vpc"
  name = "${var.environment}-${var.deployment}"
  environment = var.environment
  deployment = var.deployment

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
}

# instances
module "instances" {
  for_each = { for instance in var.instances: instance.name => instance }
  source = "./instance"
  environment = var.environment
  deployment = var.deployment
  
  ami           = module.amis.ami_map[each.value.ami_name]
  instance_type = each.value.instance_type
  iam_instance_profile = each.value.role == "app" ? module.ssm_app_profile.ec2-iam-profile.name : module.ssm_profile.ec2-iam-profile.name
  
  subnet_id = each.value.public == true ? (each.value.role == "app" ? module.vpc.public_app_subnet.id : module.vpc.public_subnet.id ) : (each.value.role == "app" ? module.vpc.private_app_subnet.id : module.vpc.private_subnet.id )
  vpc_security_group_ids = [ each.value.public == true ? (each.value.role == "app" ? module.vpc.public_app_sg.id : module.vpc.public_sg.id ) : (each.value.role == "app" ? module.vpc.private_app_sg.id : module.vpc.private_sg.id ) ]
  
  user_data = each.value.user_data
  user_data_base64 = each.value.user_data_base64

  # merge additional tags including ssm deployment tag
  tags = merge(
    module.default-ssm-tags.ssm_default_tags,
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
}

module "dns-records" {
  for_each = { for instance in local.public_compute_instances: lookup(instance.tags, "Name", "unknown") => instance }
  source          = "../../../dynu/dns_record"
  dynu_dns_domain = var.dynu_dns_domain
  
  record        = {
        recordType     = "A"
        recordName     = "${each.key}"
        recordHostName = "${each.key}.${coalesce(var.dynu_dns_domain, "unknown")}"
        recordValue    = each.value.public_ip
      }
}