
terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  region  = var.region
  profile = "root"
}

# each profile definition here
provider "aws" {
  alias   = "root"
  region  = var.region
  profile = "root"
}

provider "aws" {
  alias   = "prod"
  region  = var.region
  profile = "prod"
}

provider "aws" {
  alias   = "stage"
  region  = var.region
  profile = "stage"
}

provider "aws" {
  alias   = "test"
  region  = var.region
  profile = "test"
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
  alias        = "organization"
  organization = true
}

provider "lacework" {
  alias      = "root"
  profile    = "root"
  subaccount = "lwps"
}

provider "lacework" {
  alias      = "prod"
  profile    = "prod"
  subaccount = "lwps-prod"
}

provider "lacework" {
  alias      = "stage"
  profile    = "stage"
  subaccount = "lwps-stage"
}

provider "lacework" {
  alias      = "test"
  profile    = "test"
  subaccount = "lwps-test"
}

data "aws_availability_zones" "available" {}

# Not required: currently used in conjunction with using
# icanhazip.com to determine local workstation external IP
# to open EC2 Security Group access to the Kubernetes cluster.
# See workstation-external-ip.tf for additional information.
provider "http" {}