locals {
  kubeconfig_path = pathexpand("~/.kube/gcp-${var.environment}-${var.deployment}-kubeconfig")
}

module "gcp-gke-kubeconfig" {
  source = "../gke-kubeconfig"
  environment = var.environment
  deployment = var.deployment
  gcp_project_id = var.gcp_project_id
  gcp_location = var.gcp_location
  cluster_name = data.google_container_cluster.my_cluster.name

  depends_on = [
    google_container_node_pool.node_pool,
    google_container_cluster.cluster
  ]
}