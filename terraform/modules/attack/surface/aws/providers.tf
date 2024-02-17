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

  default_kubeconfig = try(pathexpand(module.eks-kubeconfig.kubeconfig), pathexpand("~/.kube/aws-${local.config.context.global.environment}-${local.config.context.global.deployment}-kubeconfig"))
  target_kubeconfig = pathexpand("~/.kube/aws-target-${local.config.context.global.deployment}-kubeconfig")
  attacker_kubeconfig = pathexpand("~/.kube/aws-attacker-${local.config.context.global.deployment}-kubeconfig")

  # cluster_endpoint_data     = join("", aws_eks_cluster.default[*].endpoint) # use `join` instead of `one` to keep the value a string
  # need_kubernetes_provider = local.enabled && var.apply_config_map_aws_auth

  # kubeconfig_path_enabled = local.need_kubernetes_provider && var.kubeconfig_path_enabled
  # kube_exec_auth_enabled  = local.kubeconfig_path_enabled ? false : local.need_kubernetes_provider && var.kube_exec_auth_enabled
  # kube_data_auth_enabled  = local.kube_exec_auth_enabled ? false : local.need_kubernetes_provider && var.kube_data_auth_enabled

  # exec_profile = local.kube_exec_auth_enabled && var.kube_exec_auth_aws_profile_enabled ? ["--profile", var.kube_exec_auth_aws_profile] : []
  # exec_role    = local.kube_exec_auth_enabled && var.kube_exec_auth_role_arn_enabled ? ["--role-arn", var.kube_exec_auth_role_arn] : []

  # cluster_endpoint_data     = join("", aws_eks_cluster.default[*].endpoint) # use `join` instead of `one` to keep the value a string
  # cluster_auth_map_endpoint = var.apply_config_map_aws_auth ? local.cluster_endpoint_data : var.dummy_kubeapi_server
}

# variable "dummy_kubeapi_server" {
#   type        = string
#   default     = "https://jsonplaceholder.typicode.com"
#   description = <<-EOT
#     URL of a dummy API server for the Kubernetes server to use when the real one is unknown.
#     This is a workaround to ignore connection failures that break Terraform even though the results do not matter.
#     You can disable it by setting it to `null`; however, as of Kubernetes provider v2.3.2, doing so _will_
#     cause Terraform to fail in several situations unless you provide a valid `kubeconfig` file
#     via `kubeconfig_path` and set `kubeconfig_path_enabled` to `true`.
#     EOT
# }

# provider "kubernetes" {
#   # Without a dummy API server configured, the provider will throw an error and prevent a "plan" from succeeding
#   # in situations where Terraform does not provide it with the cluster endpoint before triggering an API call.
#   # Since those situations are limited to ones where we do not care about the failure, such as fetching the
#   # ConfigMap before the cluster has been created or in preparation for deleting it, and the worst that will
#   # happen is that the aws-auth ConfigMap will be unnecessarily updated, it is just better to ignore the error
#   # so we can proceed with the task of creating or destroying the cluster.
#   #
#   # If this solution bothers you, you can disable it by setting var.dummy_kubeapi_server = null
#   host                   = local.cluster_auth_map_endpoint
#   cluster_ca_certificate = local.enabled && !local.kubeconfig_path_enabled ? base64decode(local.certificate_authority_data) : null
#   token                  = local.kube_data_auth_enabled ? one(data.aws_eks_cluster_auth.eks[*].token) : null
#   # The Kubernetes provider will use information from KUBECONFIG if it exists, but if the default cluster
#   # in KUBECONFIG is some other cluster, this will cause problems, so we override it always.
#   config_path    = local.kubeconfig_path_enabled ? var.kubeconfig_path : ""
#   config_context = var.kubeconfig_context

#   dynamic "exec" {
#     for_each = local.kube_exec_auth_enabled && length(local.cluster_endpoint_data) > 0 ? ["exec"] : []
#     content {
#       api_version = "client.authentication.k8s.io/v1beta1"
#       command     = "aws"
#       args        = concat(local.exec_profile, ["eks", "get-token", "--cluster-name", try(aws_eks_cluster.default[0].id, "deleted")], local.exec_role)
#     }
#   }
# }

data "aws_eks_cluster" "this" {
  count = var.eks_enabled ? 1 : 0
  name  = local.cluster_name
}

data "aws_eks_cluster_auth" "this" {
  count = var.eks_enabled ? 1 : 0
  name  = local.cluster_name
}

provider "kubernetes" {
  alias = "main"
  host                   = var.eks_enabled ? data.aws_eks_cluster.this.endpoint : null
  cluster_ca_certificate = var.eks_enabled ? base64decode(data.aws_eks_cluster.this.certificate_authority[0].data) : null
  token                  = var.eks_enabled ? data.aws_eks_cluster_auth.this.token : null
  config_path            = var.eks_enabled ? null : local.default_kubeconfig
}

provider "helm" {
  alias = "main"
  kubernetes {
    host                   = var.eks_enabled ? data.aws_eks_cluster.this.endpoint : null
    cluster_ca_certificate = var.eks_enabled ? base64decode(data.aws_eks_cluster.this.certificate_authority[0].data) : null
    token                  = var.eks_enabled ? data.aws_eks_cluster_auth.this.token : null
    config_path            = var.eks_enabled ? null : local.default_kubeconfig
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