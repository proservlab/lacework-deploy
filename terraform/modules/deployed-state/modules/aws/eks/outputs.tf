# provider "kubernetes" {
#   host                   = var.cluster_endpoint
#   cluster_ca_certificate = base64decode(var.cluster_ca_cert)
#   exec {
#     api_version = "client.authentication.k8s.io/v1beta1"
#     args        = ["eks", "get-token", "--cluster-name", var.cluster_name]
#     command     = "aws"
#   }
# }

output "cluster_endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "cluster_ca_cert" {
  value = data.aws_eks_cluster.cluster.certificate_authority[0].data
}

output "exec_api_version" {
  value = "client.authentication.k8s.io/v1beta1"
}

output "exec_args" {
    value = ["eks", "get-token", "--region", var.region, "--profile", var.aws_profile_name, "--cluster-name", "${var.cluster_name}-${var.environment}-${var.deployment}"]
}

output "exec_command" {
    value = "aws"
}