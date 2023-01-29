data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
    kubeconfig_path = pathexpand("~/.kube/aws-${var.environment}-${var.deployment}-kubeconfig")
}

data "template_file" "kubeconfig" {
  template = file("${path.module}/resources/kubeconfig.yaml.tpl")

  vars = {
    cluster_endpoint = aws_eks_cluster.cluster.endpoint
    cluster_certificate_authority = aws_eks_cluster.cluster.certificate_authority[0].data
    aws_profile_name = var.aws_profile_name
    aws_region = var.region
    cluster_name = "${var.cluster_name}-${var.environment}-${var.deployment}"
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
                touch ${local.kubeconfig_path}
                truncate -s 0 ${local.kubeconfig_path}
                aws eks wait cluster-active --profile '${var.aws_profile_name}' --name '${var.cluster_name}-${var.environment}-${var.deployment}'
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}-${var.environment}-${var.deployment}' --alias '${var.cluster_name}-${var.region}-${var.environment}-${var.deployment}' --region=${var.region}
              EOT
  }
}