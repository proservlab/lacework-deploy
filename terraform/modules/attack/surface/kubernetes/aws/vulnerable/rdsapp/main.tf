
##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../../../../context/deployment"
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}