locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = can(length(local.default_infrastructure_config.context.aws.profile_name)) ? null : "mock_access_key"
  secret_key = can(length(local.default_infrastructure_config.context.aws.profile_name)) ? null : "mock_secret_key"
}

provider "aws" {
  profile = local.default_infrastructure_config.context.aws.profile_name
  region = local.default_infrastructure_config.context.aws.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "aws" {
  alias = "attacker"
  profile = local.attacker_infrastructure_config.context.aws.profile_name
  region = local.attacker_infrastructure_config.context.aws.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "aws" {
  alias = "target"
  profile = local.target_infrastructure_config.context.aws.profile_name
  region = local.target_infrastructure_config.context.aws.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "kubernetes" {
  config_path = local.kubeconfig_path
}

provider "helm" {
  kubernetes {
    config_path = local.kubeconfig_path
  }
}