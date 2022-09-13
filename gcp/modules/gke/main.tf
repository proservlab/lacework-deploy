data "google_client_config" "current" {}

# create a service account
resource "google_service_account" "default" {
  account_id   = "${var.environment}-gke-service-account"
  display_name = "${var.environment}-gke-service-account"
}

resource "google_container_cluster" "cluster" {
  name     = "${var.environment}-cluster"
  location = "us-central1"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}

resource "google_container_node_pool" "nodes" {
  name       = "${var.environment}-nodes"
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
    preemptible  = true
    machine_type = var.nodes_instance_type

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
}

# Retrieve an access token as the Terraform runner
data "google_client_config" "provider" {}

data "google_container_cluster" "my_cluster" {
  name     = "${var.environment}-cluster"
  location = "us-central1"

  depends_on = [
    google_container_node_pool.nodes, google_container_cluster.cluster
  ]
}
