output "private_vpc_network" {
  value = google_compute_network.network.self_link
}

output "cluster_endpoint" {
  value = data.google_container_cluster.my_cluster.endpoint
}

output "cluster_ca_certificate" {
  value = data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate
}

