output "kubeconfig_path" {
  value = module.gcp-gke-kubeconfig.kubeconfig_path
}

output "cluster_endpoint" {
  value = data.google_container_cluster.my_cluster.endpoint
}

output "cluster_ca_certificate" {
  value = data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate
}

output "cluster_network" {
  value = google_compute_network.vpc_network
}

output "cluster_subnetwork" {
  value = google_compute_subnetwork.vpc_subnetwork
}

output "cluster_nat_public_ip" {
  value = data.google_compute_address.static_ip
}

