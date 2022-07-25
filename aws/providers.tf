terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = var.region
  profile = "proservlab"
}

# each profile definition here
provider "aws" {
  alias   = "proservlab"
  region  = var.region
  profile = "proservlab"
}

provider "aws" {
  alias   = "dev-prod"
  region  = var.region
  profile = "dev-prod"
}

provider "aws" {
  alias   = "dev-stage"
  region  = var.region
  profile = "dev-stage"
}

provider "aws" {
  alias   = "dev-test"
  region  = var.region
  profile = "dev-test"
}

provider "aws" {
  alias   = "log"
  region  = var.region
  profile = "log"
}

provider "aws" {
  alias   = "audit"
  region  = var.region
  profile = "audit"
}


provider "lacework" {
  alias   = "proservlab"
  profile = "proservlab"
}
# provider "lacework" {
#   alias        = "proservlab-organization"
#   organization = true
# }

# provider "lacework" {
#   alias      = "proservlab"
#   profile    = "proservlab"
# }

# provider "lacework" {
#   alias      = "dev-prod"
#   profile    = "dev-prod"
#   subaccount = "proservlab-prod"
# }

# provider "lacework" {
#   alias      = "dev-stage"
#   profile    = "dev-stage"
#   subaccount = "proservlab-stage"
# }

# provider "lacework" {
#   alias      = "dev-test"
#   profile    = "dev-test"
#   subaccount = "proservlab-test"
# }

data "aws_availability_zones" "available" {}

# Not required: currently used in conjunction with using
# icanhazip.com to determine local workstation external IP
# to open EC2 Security Group access to the Kubernetes cluster.
# See workstation-external-ip.tf for additional information.
provider "http" {}