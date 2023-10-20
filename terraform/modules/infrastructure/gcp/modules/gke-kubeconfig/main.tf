locals {
  kubeconfig_path = fileexists(var.kubeconfig_path) ? var.kubeconfig_path : (
    fileexists(pathexpand("~/.kube/gcp-${var.environment}-${var.deployment}-kubeconfig")) ? pathexpand("~/.kube/gcp-${var.environment}-${var.deployment}-kubeconfig") : pathexpand("~/.kube/config") 
  ) 
  kubeconfig = templatefile(
                              "${path.module}/resources/kubeconfig.yaml.tpl",
                              {
                                cluster_endpoint = data.google_container_cluster.provider.endpoint
                                cluster_certificate_authority = data.google_container_cluster.provider.master_auth[0].cluster_ca_certificate
                                gcp_project_id = var.gcp_project_id
                                gcp_location = var.gcp_location
                                cluster_name = "${var.cluster_name}"
                              }
                            )
}

data "google_container_cluster" "provider" {
  name     = "${var.cluster_name}"
  location = var.gcp_location
}

# for _user convenience_ ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "gke_context_switcher" {

  triggers = {
    always = timestamp()
  }

  depends_on = [
      data.google_container_cluster.provider,
      local_file.kubeconfig
    ]

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


resource "time_sleep" "wait_60_seconds" {
  depends_on = [null_resource.gke_context_switcher]

  create_duration = "60s"
}

data "local_file" "kubeconfig" {
  filename = pathexpand(local.kubeconfig_path)

  depends_on = [ time_sleep.wait_60_seconds ]
}