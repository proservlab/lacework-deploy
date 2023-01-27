data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
    kubeconfig_path = pathexpand("~/.kube/aws-${var.environment}-${var.deployment}-kubeconfig")
}

# ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "eks_context_switcher" {
  triggers = {
    always = timestamp()
  }

  depends_on = [aws_eks_cluster.cluster]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<EOT
      set -e
      echo 'Applying Auth ConfigMap with kubectl...'
      aws eks wait cluster-active --profile '${var.aws_profile_name}' --name '${var.cluster_name}-${var.environment}-${var.deployment}'
      aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}-${var.environment}-${var.deployment}' --alias '${var.cluster_name}-${var.region}-${var.environment}-${var.deployment}' --region=${var.region}
      aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}-${var.environment}-${var.deployment}' --alias '${var.cluster_name}-${var.region}-${var.environment}-${var.deployment}' --region=${var.region} --kubeconfig=${local.kubeconfig_path}
    EOT
  }
}