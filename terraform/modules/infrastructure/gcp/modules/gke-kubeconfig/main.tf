locals {
  kubeconfig_path = pathexpand("~/.kube/gcp-${var.environment}-${var.deployment}-kubeconfig")
}

data "google_container_cluster" "provider" {
  name     = "${var.cluster_name}"
  location = var.gcp_location
}

data "template_file" "kubeconfig" {
  template = file("${path.module}/resources/kubeconfig.yaml.tpl")

  vars = {
    cluster_endpoint = data.google_container_cluster.provider.endpoint
    cluster_certificate_authority = data.google_container_cluster.provider.master_auth[0].cluster_ca_certificate
    gcp_region = var.gcp_location
    cluster_name = "${var.cluster_name}"
  }
}

resource "local_file" "kubeconfig" {
  filename = local.kubeconfig_path
  content = data.template_file.kubeconfig.rendered
}

# for _user convenience_ ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
resource "null_resource" "gke_context_switcher" {

  triggers = {
    always = timestamp()
  }

  depends_on = [data.google_container_cluster.provider]

  # update kubeconfg specific config
  provisioner "local-exec" {
    command = <<-EOT
              set -e
              gcloud container clusters get-credentials ${var.cluster_name} --region=${var.gcp_location}
              export KUBECONFIG=${local.kubeconfig_path}
              gcloud container clusters get-credentials ${var.cluster_name} --region=${var.gcp_location}
              EOT
  }
}