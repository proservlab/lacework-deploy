data "google_client_config" "current" {}

resource "google_container_cluster" "primary" {
  name     = "${var.environment_name}-cluster"
  location = var.region

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_cluster" "cluster" {
  name     = "${var.environment_name}-cluster"
  location = var.region

  network    = google_compute_network.network.self_link
  subnetwork = google_compute_subnetwork.subnet.self_link

  ip_allocation_policy {}

  min_master_version = var.cluster_version

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1

  master_auth {
    # username = var.cluster_username
    # password = var.cluster_password

    client_certificate_config {
      issue_client_certificate = false
    }
  }
}

resource "google_container_node_pool" "nodes" {
  name       = "${var.environment_name}-nodes"
  location   = var.region
  cluster    = google_container_cluster.cluster.name
  node_count = 1

  autoscaling {
    min_node_count = var.nodes_min_size
    max_node_count = var.nodes_max_size
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  node_config {
    machine_type = var.nodes_instance_type

    metadata = {
      disable-legacy-endpoints = "true"
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/cloud-platform",
    ]
  }
}

# Retrieve an access token as the Terraform runner
data "google_client_config" "provider" {}

data "google_container_cluster" "my_cluster" {
  name     = "${var.environment_name}-cluster"
  location = "us-central1"

  depends_on = [
    google_container_node_pool.nodes, google_container_cluster.cluster
  ]
}
