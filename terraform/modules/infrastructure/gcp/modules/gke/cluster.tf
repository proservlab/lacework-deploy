data "google_compute_zones" "available" {
  project     = var.gcp_project_id
  region    = var.gcp_location
}

locals {
  gcp_region         = data.google_compute_zones.available.names[0]
  release_channel    = var.release_channel == "" ? [] : [var.release_channel]
  min_master_version = var.release_channel == "" ? var.min_master_version : ""
  identity_namespace = var.identity_namespace == "" ? [] : [var.identity_namespace]
  authenticator_security_group = var.authenticator_security_group == "" ? [] : [var.authenticator_security_group]
}

resource "google_compute_address" "static_ip" {
  name    = "${var.cluster_name}-${var.environment}-${var.deployment}-nat-ip"
  region  = var.gcp_location
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.vpc_network_name}-${var.environment}-${var.deployment}"
  auto_create_subnetworks = "false"
  project                 = var.gcp_project_id
}

resource "google_compute_subnetwork" "vpc_subnetwork" {
  name    = "${var.vpc_subnetwork_name}-${var.environment}-${var.deployment}"
  region  = var.gcp_location
  project = var.gcp_project_id

  ip_cidr_range = var.vpc_subnetwork_cidr_range

  network = google_compute_network.vpc_network.name

  secondary_ip_range {
    range_name    = var.cluster_secondary_range_name
    ip_cidr_range = var.cluster_secondary_range_cidr
  }
  
  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_range_cidr
  }

  private_ip_google_access = true

  depends_on = [
    google_compute_network.vpc_network,
  ]
}

resource "google_compute_router" "router" {
  count   = var.enable_cloud_nat ? 1 : 0
  name    = "${var.cluster_name}-${var.environment}-${var.deployment}-router"
  region  = var.gcp_location
  network = google_compute_network.vpc_network.self_link
}

resource "google_compute_router_nat" "nat" {
  count = var.enable_cloud_nat ? 1 : 0
  name  = "${var.cluster_name}-${var.environment}-${var.deployment}-nat"
  // Because router has the count attribute set we have to use [0] here to
  // refer to its attributes.
  router = google_compute_router.router[0].name
  region = google_compute_router.router[0].region
  nat_ip_allocate_option = "MANUAL_ONLY"
  nat_ips = ["${google_compute_address.static_ip.self_link}"]
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = var.enable_cloud_nat_logging
    filter = var.cloud_nat_logging_filter
  }
}

resource "google_container_cluster" "cluster" {
  location = var.gcp_location
  project = var.gcp_project_id

  name = "${var.cluster_name}-${var.environment}-${var.deployment}"

  min_master_version = local.min_master_version

  dynamic "release_channel" {
    for_each = toset(local.release_channel)

    content {
      channel = release_channel.value
    }
  }

  dynamic "authenticator_groups_config" {
    for_each = toset(local.authenticator_security_group)

    content {
      security_group = authenticator_groups_config.value
    }
  }
  maintenance_policy {
    daily_maintenance_window {
      start_time = var.daily_maintenance_window_start_time
    }
  }

  private_cluster_config {
    enable_private_endpoint = var.private_endpoint
    enable_private_nodes    = var.private_nodes

    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }


  network_policy {
    enabled = true

    provider = "CALICO"
  }

  master_auth {

    client_certificate_config {
      issue_client_certificate = false
    }
  }

  addons_config {
    http_load_balancing {
      disabled = var.http_load_balancing_disabled
    }

    network_policy_config {
      disabled = false
    }
  }

  network    = google_compute_network.vpc_network.name
  subnetwork = google_compute_subnetwork.vpc_subnetwork.name

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  remove_default_node_pool = true

  initial_node_count = 1

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks_cidr_blocks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  logging_service = var.stackdriver_logging != "false" ? "logging.googleapis.com/kubernetes" : ""

  monitoring_service = var.stackdriver_monitoring != "false" ? "monitoring.googleapis.com/kubernetes" : ""

  timeouts {
    update = "20m"
  }

  depends_on = [
    google_compute_subnetwork.vpc_subnetwork
  ]
}

resource "google_container_node_pool" "node_pool" {
  location = google_container_cluster.cluster.location
  count = length(var.node_pools)
  name = format("%s-pool", lookup(var.node_pools[count.index], "name", format("%03d", count.index + 1)))
  cluster = google_container_cluster.cluster.name
  initial_node_count = lookup(var.node_pools[count.index], "initial_node_count", 1)

  autoscaling {
    min_node_count = lookup(var.node_pools[count.index], "autoscaling_min_node_count", 2)
    max_node_count = lookup(var.node_pools[count.index], "autoscaling_max_node_count", 3)
  }

  version = lookup(var.node_pools[count.index], "version", "")
  
  management {
    auto_repair = lookup(var.node_pools[count.index], "auto_repair", true)
    auto_upgrade = lookup(var.node_pools[count.index], "version", "") == "" ? lookup(var.node_pools[count.index], "auto_upgrade", true) : false
  }

  node_config {
    machine_type = lookup(
      var.node_pools[count.index],
      "node_config_machine_type",
      "n1-standard-1",
    )

    service_account = google_service_account.default.email

    disk_size_gb = lookup(
      var.node_pools[count.index],
      "node_config_disk_size_gb",
      100
    )

    disk_type = lookup(
      var.node_pools[count.index],
      "node_config_disk_type",
      "pd-standard",
    )

    preemptible = lookup(
      var.node_pools[count.index],
      "node_config_preemptible",
      false,
    )

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    metadata = {
      disable-legacy-endpoints = "true"
    }
  }

  timeouts {
    update = "20m"
  }
}

data "google_container_cluster" "my_cluster" {
  name     = google_container_cluster.cluster.name
  location = var.gcp_location

  depends_on = [
    google_container_node_pool.node_pool,
    google_container_cluster.cluster
  ]
}