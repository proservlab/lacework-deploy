locals {
  # ugly hack to force ignoring unconfigure aws provider
  access_key = coalesce(local.default_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  secret_key = coalesce(local.default_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  profile = coalesce(local.default_infrastructure_config.context.aws.profile_name, "false") == "false" ? null : local.default_infrastructure_config.context.aws.profile_name
  region = coalesce(local.default_infrastructure_config.context.aws.profile_name, "false") == "false" ? "us-east-1" : local.default_infrastructure_config.context.aws.region

  attacker_access_key = coalesce(local.attacker_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  attacker_secret_key = coalesce(local.attacker_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  attacker_profile = coalesce(local.attacker_infrastructure_config.context.aws.profile_name, "false") == "false" ? null : local.attacker_infrastructure_config.context.aws.profile_name
  attacker_region = coalesce(local.attacker_infrastructure_config.context.aws.profile_name, "false") == "false" ? "us-east-1" : local.attacker_infrastructure_config.context.aws.region

  target_access_key = coalesce(local.target_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_access_key"
  target_secret_key = coalesce(local.target_infrastructure_config.context.aws.profile_name, "false") != "false" ? null : "mock_secret_key"
  target_profile = coalesce(local.target_infrastructure_config.context.aws.profile_name, "false") == "false" ? null : local.target_infrastructure_config.context.aws.profile_name
  target_region = coalesce(local.target_infrastructure_config.context.aws.profile_name, "false") == "false" ? "us-east-1" : local.target_infrastructure_config.context.aws.region

  default_kubeconfig = pathexpand("~/.kube/aws-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig")
  target_kubeconfig = pathexpand("~/.kube/aws-target-${local.config.context.global.deployment}-kubeconfig")
  attacker_kubeconfig = pathexpand("~/.kube/aws-attacker-${local.config.context.global.deployment}-kubeconfig")
}

resource "null_resource" "wait_for_cluster" {
  count = var.eks_enabled ? 1 : 0
  triggers = {
    always = timestamp()
    "before" = "${data.aws_eks_cluster.this[0].id}"
  }
  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
                echo "Waiting for cluster: ${local.cluster_name} [${local.cluster_endpoint}]"
                aws --profile '${var.default_aws_profile}' eks wait cluster-active --region=${var.default_aws_region} --name '${local.cluster_name}'
              EOT
    environment = {
      ENDPOINT = local.cluster_endpoint
    }
  }
}

data "aws_eks_cluster" "this" {
  count = var.eks_enabled ? 1 : 0
  name  = local.cluster_name
}

data "local_file" "default_kubeconfig" {
  filename = local.default_kubeconfig
  depends_on = [ data.aws_eks_cluster.this ]
}

# provider "kubernetes" {
#   config_path             = data.local_file.default_kubeconfig.filename
# }

provider "kubernetes" {
  alias = "main"
  config_path             = data.local_file.default_kubeconfig.filename
}

# provider "helm" {
#   kubernetes {
#     config_path           = data.local_file.default_kubeconfig.filename
#   }
# }

provider "helm" {
  alias = "main"
  kubernetes {
    config_path           = data.local_file.default_kubeconfig.filename
  }
}

provider "aws" {
  profile = var.default_aws_profile
  region = var.default_aws_region
}

provider "aws" {
  alias = "attacker"
  profile = var.attacker_aws_profile
  region = var.attacker_aws_region
}

provider "aws" {
  alias = "target"
  profile = var.target_aws_profile
  region = var.target_aws_region
}

provider "lacework" {
  profile    = var.default_lacework_profile
}

provider "restapi" {
  uri                  = "https://api.dynu.com/v2"
  write_returns_object = true
  debug                = true

  headers = {
    "API-Key" = try(local.default_infrastructure_config.context.dynu_dns.api_key, ""),
    "Content-Type" = "application/json"
  }

  create_method  = "POST"
  update_method  = "PUT"
  destroy_method = "DELETE"
}