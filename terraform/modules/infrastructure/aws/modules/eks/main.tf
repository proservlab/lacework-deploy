data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
    kubeconfig_path = pathexpand("~/.kube/aws-${var.environment}-${var.deployment}-kubeconfig")
}

data "aws_eks_cluster" "provider" {
  name = aws_eks_cluster.cluster.id
  depends_on = [
    aws_eks_cluster.cluster
  ]
}

data "template_file" "kubeconfig" {
  template = file("${path.module}/resources/kubeconfig.yaml.tpl")

  vars = {
    cluster_endpoint = data.aws_eks_cluster.provider.endpoint
    cluster_certificate_authority = data.aws_eks_cluster.provider.certificate_authority[0].data
    cluster_arn = data.aws_eks_cluster.provider.arn
    aws_profile_name = var.aws_profile_name
    aws_region = var.region
    cluster_name = data.aws_eks_cluster.provider.id
  }
}

resource "local_file" "kubeconfig" {
  filename = local.kubeconfig_path
  content = data.template_file.kubeconfig.rendered
}

# for _user convenience_ ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "eks_context_switcher" {
  triggers = {
    always = timestamp()
  }

  depends_on = [aws_eks_cluster.cluster]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
                set -e
                echo 'Applying Auth ConfigMap with kubectl...'
                aws eks wait cluster-active --profile '${var.aws_profile_name}' --name '${var.cluster_name}-${var.environment}-${var.deployment}'
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}-${var.environment}-${var.deployment}' --alias '${var.cluster_name}-${var.region}-${var.environment}-${var.deployment}' --region=${var.region}
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}-${var.environment}-${var.deployment}' --alias '${var.cluster_name}-${var.region}-${var.environment}-${var.deployment}' --region=${var.region} --kubeconfig=${local.kubeconfig_path}
              EOT
  }
}