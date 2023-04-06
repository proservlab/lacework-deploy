locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(var.config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  profile = coalesce(var.config.context.aws.profile_name, "false") == "false" ? null : var.config.context.aws.profile_name
  region = coalesce(var.config.context.aws.profile_name, "false") == "false" ? "us-east-1" : var.config.context.aws.region

  kubeconfig_path = pathexpand("~/.kube/config")
}

provider "kubernetes" {
  alias = "main"
  host                   = try(length(local.cluster_endpoint), "false" ) != "false" ? local.cluster_endpoint : "http://localhost"
  cluster_ca_certificate = try(length(local.cluster_ca_cert), "false" ) != "false" ? base64decode(local.cluster_ca_cert) : null
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["--region", local.aws_region, "--profile", local.aws_profile_name, "eks", "get-token", "--cluster-name", local.cluster_name] 
    command     = "aws"
  }
}

provider "helm" {
  alias = "main"
  kubernetes {
    host                   = try(length(local.cluster_endpoint), "false" ) != "false" ? local.cluster_endpoint : "http://localhost"
    cluster_ca_certificate = try(length(local.cluster_ca_cert), "false" ) != "false" ? base64decode(local.cluster_ca_cert) : null
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["--region", local.aws_region, "--profile", local.aws_profile_name, "eks", "get-token", "--cluster-name", local.cluster_name]
      command     = "aws"
    }
  }
}

provider "aws" {
  max_retries = 40

  profile = local.profile
  region = local.region
  access_key                  = local.access_key
  secret_key                  = local.secret_key
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_requesting_account_id  = true
}

provider "lacework" {
  profile    = can(length(var.config.context.lacework.profile_name)) ? var.config.context.lacework.profile_name : null
  account    = can(length(var.config.context.lacework.profile_name)) ? null : "my-account"
  api_key    = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-key"
  api_secret = can(length(var.config.context.lacework.profile_name)) ? null : "my-api-secret"
}

provider "restapi" {
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = var.config.context.dynu_dns.api_token,
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}