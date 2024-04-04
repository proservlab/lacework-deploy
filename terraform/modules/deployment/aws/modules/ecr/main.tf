module "lacework_ecr" {
  source  = "lacework/ecr/aws"
  version = "~> 0.9"

#   lacework_integration_name = "custom integration name"
  non_os_package_support    = true
  tags = {
    environment = var.environment
    deployment = var.deployment

  }

#   limit_by_tags         = ["example*"]
#   limit_by_labels       = {example: "example"}
#   limit_by_repositories = ["foo","bar"]
}