data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
    kubeconfig_path = pathexpand("~/.kube/aws-${var.environment}-${var.deployment}-kubeconfig")
}

# for _user convenience_ ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "eks_context_switcher" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
                echo 'Applying Auth ConfigMap with kubectl...'
                aws eks wait cluster-active --profile '${var.aws_profile_name}' --region=${var.region} --name '${aws_eks_cluster.cluster.id}'
                if ! command -v yq; then
                  curl -LJ https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq &&\
                  chmod +x /usr/local/bin/yq
                fi
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${aws_eks_cluster.cluster.id}' --region=${var.region}
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${aws_eks_cluster.cluster.id}' --region=${var.region} --kubeconfig="${local.kubeconfig_path}"
                yq -i -r '(.users[] | select(.name == "${aws_eks_cluster.cluster.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i "${local.kubeconfig_path}"
                yq -i -r '(.users[] | select(.name == "${aws_eks_cluster.cluster.arn}")|.user.exec.env[0].value) = "${var.aws_profile_name}"' -i "${local.kubeconfig_path}"
                yq -i -r '(.users[] | select(.name == "${aws_eks_cluster.cluster.arn}")|.user.exec.env[1].name) = "AWS_REGION"' -i "${local.kubeconfig_path}"
                yq -i -r '(.users[] | select(.name == "${aws_eks_cluster.cluster.arn}")|.user.exec.env[1].value) = "${var.region}"' -i "${local.kubeconfig_path}"
                yq -i -r '(.users[] | select(.name == "${aws_eks_cluster.cluster.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${aws_eks_cluster.cluster.arn}")|.user.exec.env[0].value) = "${var.aws_profile_name}"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${aws_eks_cluster.cluster.arn}")|.user.exec.env[1].name) = "AWS_REGION"' -i "${pathexpand("~/.kube/config")}"
                yq -i -r '(.users[] | select(.name == "${aws_eks_cluster.cluster.arn}")|.user.exec.env[1].value) = "${var.region}"' -i "${pathexpand("~/.kube/config")}"
                
              EOT
  }

  depends_on = [ 
    aws_eks_cluster.cluster
  ]
}

data "local_file" "kubeconfig_path" {
  filename = local.kubeconfig_path

  depends_on = [ 
    aws_eks_cluster.cluster,
    null_resource.eks_context_switcher 
  ]
}