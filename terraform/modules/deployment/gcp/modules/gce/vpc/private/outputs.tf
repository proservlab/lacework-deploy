output "network" {
    value = google_compute_network.network
}

output "subnetwork" {
    value = google_compute_subnetwork.subnetwork
}

output "private_nat_gw" {
    value = google_compute_address.nat-ip
}