module "lacework_ecr" {
  source  = "lacework/ecr/aws"
  version = "~> 0.9"
  
  non_os_package_support    = true
  tags = {
    environment = var.environment
    deployment = var.deployment

  }
}