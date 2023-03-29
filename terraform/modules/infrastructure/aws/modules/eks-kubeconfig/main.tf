# locals {
#     kubeconfig_path = pathexpand("~/.kube/aws-${var.environment}-${var.deployment}-kubeconfig")
#     kubeconfig = templatefile(
#                                 "${path.module}/resources/kubeconfig.yaml.tpl",
#                                 {
#                                   cluster_endpoint = data.aws_eks_cluster.provider.endpoint
#                                   cluster_certificate_authority = data.aws_eks_cluster.provider.certificate_authority[0].data
#                                   cluster_arn = data.aws_eks_cluster.provider.arn
#                                   aws_profile_name = var.aws_profile_name
#                                   aws_region = var.region
#                                   cluster_name = data.aws_eks_cluster.provider.id
#                                 }
#                               )
# }

# data "aws_eks_cluster" "provider" {
#   name = "${var.cluster_name}"
# }

# resource "local_file" "kubeconfig" {
#   filename = local.kubeconfig_path
#   content = local.kubeconfig
# }

# for _user convenience_ ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "eks_context_switcher" {
  triggers = {
    always = timestamp()
  }

  depends_on = [
        data.aws_eks_cluster.provider,
        local_file.kubeconfig
    ]

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
                set -e
                echo 'Applying Auth ConfigMap with kubectl...'
                aws eks wait cluster-active --profile '${var.aws_profile_name}' --name '${var.cluster_name}'
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}' --region=${var.region}
              EOT
  }
}

# resource "time_sleep" "wait_60_seconds" {
#   depends_on = [null_resource.eks_context_switcher]

#   create_duration = "60s"
# }