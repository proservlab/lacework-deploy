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
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}' --region=${var.region}
                aws eks update-kubeconfig --profile '${var.aws_profile_name}' --name '${var.cluster_name}' --region=${var.region} --kubeconfig=${var.kubeconfig_path}
              EOT
  }
}

resource "time_sleep" "wait_60_seconds" {
  depends_on = [
    null_resource.eks_context_switcher
  ]

  create_duration = "60s"
}

data "local_file" "kubeconfig" {
  filename = var.kubeconfig_path

  depends_on = [
    time_sleep.wait_60_seconds
  ]
}