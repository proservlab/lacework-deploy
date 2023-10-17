locals {
  kubeconfig_path = pathexpand("~/.kube/gcp-${var.environment}-${var.deployment}-kubeconfig")
}

# for _user convenience_ ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "gke_context_switcher" {

  triggers = {
    always = timestamp()
  }

  # update kubeconfg specific config
  provisioner "local-exec" {
    command = <<-EOT
              set -e
              export CLOUDSDK_CORE_PROJECT=${var.gcp_project_id}
              gcloud container clusters get-credentials ${var.cluster_name} --region=${var.gcp_location}
              export KUBECONFIG=${local.kubeconfig_path}
              gcloud container clusters get-credentials ${var.cluster_name} --region=${var.gcp_location}
              EOT
  }
}

data "local_file" "kubeconfig" {
  filename = local.kubeconfig_path
}