locals {
  kubeconfig_path = pathexpand("~/.kube/azure-${var.environment}-${var.deployment}-kubeconfig")
}

# for _user convenience_ ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "aks_context_switcher" {

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
     command = <<-EOT
                set -e
                echo 'Applying Auth ConfigMap with kubectl...'
                az aks get-credentials -n ${var.cluster_name} -g ${var.cluster_resource_group} --overwrite-existing
                az aks get-credentials -n ${var.cluster_name} -g ${var.cluster_resource_group} --overwrite-existing --file=${local.kubeconfig_path}
              EOT
    
  }
}

data "local_file" "kubeconfig" {
  filename = local.kubeconfig_path
}