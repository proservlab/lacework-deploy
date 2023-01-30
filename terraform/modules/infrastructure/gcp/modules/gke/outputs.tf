output "kubeconfig_path" {
  value = module.gcp-gke-kubeconfig.kubeconfig_path
}

output "cluster_endpoint" {
  value = data.google_container_cluster.my_cluster.endpoint
}

output "cluster_ca_certificate" {
  value = data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate
}

