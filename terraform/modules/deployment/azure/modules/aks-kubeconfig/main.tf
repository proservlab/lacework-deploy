locals {
  kubeconfig_path = fileexists(var.kubeconfig_path) ? var.kubeconfig_path : (
    fileexists(pathexpand("~/.kube/azure-${var.environment}-${var.deployment}-kubeconfig")) ? pathexpand("~/.kube/azure-${var.environment}-${var.deployment}-kubeconfig") : pathexpand("~/.kube/config") 
  ) 
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


resource "time_sleep" "wait_60_seconds" {
  depends_on = [null_resource.aks_context_switcher]

  create_duration = "60s"
}

data "local_file" "kubeconfig" {
  filename = pathexpand(local.kubeconfig_path)

  depends_on = [ time_sleep.wait_60_seconds ]
}