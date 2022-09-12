output "private_vpc_network" {
  value = google_compute_network.network.self_link
}