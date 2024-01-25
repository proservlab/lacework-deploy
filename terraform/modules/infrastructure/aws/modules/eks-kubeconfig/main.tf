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
                echo 'Applying Auth ConfigMap with kubectl...'
                aws eks wait cluster-active --profile '${var.aws_profile_name}' --region=${var.region} --name '${var.cluster_name}'
                if ! command -v yq; then
                  curl -LJ https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -o /usr/local/bin/yq &&\
                  chmod +x /usr/local/bin/yq
                fi
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}' --region=${var.region}
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}' --region=${var.region} --kubeconfig=${pathexpand(var.kubeconfig_path)}
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i $HOME/.kube/config
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].value) = "${var.aws_profile_name}"' -i $HOME/.kube/config
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].name) = "AWS_REGION"' -i $HOME/.kube/config
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].value) = "${var.region}"' -i $HOME/.kube/config
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].name) = "AWS_PROFILE"' -i ${pathexpand(var.kubeconfig_path)}
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].value) = "${var.aws_profile_name}"' -i ${pathexpand(var.kubeconfig_path)}
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].name) = "AWS_REGION"' -i ${pathexpand(var.kubeconfig_path)}
                yq -i -r '(.users[] | select(.name == "${data.aws_eks_cluster.this.arn}")|.user.exec.env[0].value) = "${var.region}"' -i ${pathexpand(var.kubeconfig_path)}
              EOT
  }

  depends_on = [ data.aws_eks_cluster.this ]
}

data "local_file" "kubeconfig" {
  filename = var.kubeconfig_path

  depends_on = [ 
    null_resource.eks_context_switcher 
  ]
}