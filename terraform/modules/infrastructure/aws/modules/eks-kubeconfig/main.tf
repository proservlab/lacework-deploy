data "aws_eks_cluster" "this" {
  name = var.cluster_name
}

# for _user convenience_ ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "eks_context_switcher" {
  triggers = {
    always = timestamp()
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-c"]
    command = <<-EOT
                set -e
                echo 'Applying Auth ConfigMap with kubectl...'
                aws eks wait cluster-active --profile '${var.aws_profile_name}' --name '${var.cluster_name}'
                if ! command -v yq; then
                  wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq &&\
                  chmod +x /usr/local/bin/yq
                fi
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}' --region=${var.region}
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}' --region=${var.region} --kubeconfig=${var.kubeconfig_path}
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i ~/.kube/config
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].value) = "${var.aws_profile_name}"' -i ~/.kube/config
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i ${var.kubeconfig_path}
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].value) = "${var.aws_profile_name}"' -i ${var.kubeconfig_path}
              EOT
  }
}

data "local_file" "kubeconfig" {
  filename = var.kubeconfig_path

  depends_on = [ 
    null_resource.eks_context_switcher 
  ]
}