# lookup latest amis
module "amis" {
  source = "./amis"
}

# create an ssm iam instance profile
module "ssm_profile" {
  source = "./ssm-profile"
  environment = var.environment
}

# build private and public vpcs
module "vpc" {
  source = "./vpc"
  name = "main"
  environment = var.environment
  private_ingress_rules = var.private_ingress_rules
  private_egress_rules = var.private_egress_rules
  public_ingress_rules = var.public_ingress_rules
  public_egress_rules = var.public_egress_rules
}

# instances
module "instances" {
  for_each = { for instance in var.instances: instance.name => instance }
  source = "./instance"
  environment = var.environment
  
  ami           = module.amis.ami_map[each.value.ami_name]
  instance_type = each.value.instance_type
  iam_instance_profile = each.value.enable_ssm == true ? module.ssm_profile.ec2-iam-profile.name : null
  
  subnet_id = each.value.public == true ? module.vpc.public_subnet.id : module.vpc.private_subnet.id
  vpc_security_group_ids = [ each.value.public == true ? module.vpc.public_sg.id : module.vpc.private_sg.id ]
  
  user_data = each.value.user_data
  user_data_base64 = each.value.user_data_base64

  # merge additional tags including ssm deployment tag
  tags = merge(
            {
              Name = each.value.name
              Environment = var.environment
              public = each.value.public
            },
            each.value.tags, 
            each.value.enable_ssm == true ? each.value.ssm_deploy_tag : {}
          )
}