resource "google_compute_router" "router" {
  name                                  = "${var.environment}-${var.deployment}-${var.role}-router"
  project = var.gcp_project_id
  region  = google_compute_subnetwork.subnetwork.region
  network = google_compute_network.network.id
}

resource "google_compute_router_nat" "nat" {
    name                                = "${var.environment}-${var.deployment}-${var.role}-router-nat"
    router                              = google_compute_router.router.name
    project                             = var.gcp_project_id
    region                              = google_compute_router.router.region
    nat_ip_allocate_option              = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"

    log_config {
    enable                              = true
        filter                          = "ERRORS_ONLY"
    }
}

resource "google_compute_network" "network" {
    name                                = "${var.environment}-${var.deployment}-${var.role}-vpc"
    auto_create_subnetworks             = "false"
    project                             = var.gcp_project_id
}

resource "google_compute_subnetwork" "subnetwork" {
    name                                = "${var.environment}-${var.deployment}-${var.role}-subnetwork"
    ip_cidr_range                       = var.private_subnet
    region                              = var.gcp_location
    project                             = var.gcp_project_id
    network                             = google_compute_network.network.name
  
    # secondary_ip_range {
    #     range_name                      = "${var.environment}-${var.deployment}-${var.role}-secondary-ip-range"
    #     ip_cidr_range                   = var.private_subnet
    # }

    depends_on = [
        google_compute_network.network,
    ]
}

resource "google_compute_address" "nat-ip" {
    name                                = "${var.environment}-${var.deployment}-${var.role}-nat-ip"
    project                             = var.gcp_project_id
    region                              = var.gcp_location
}

resource "google_compute_firewall" "ingress_rules" {
  count                   = length(var.private_ingress_rules)
  name                    = "${var.environment}-${var.deployment}-${var.role}-ingress-rule"
  description             = "${var.environment}-${var.deployment}-${var.role}-ingress-rule"
  direction               = "INGRESS"
  network                 = google_compute_network.network.name
  project                 = var.gcp_project_id
  source_ranges           = [var.private_ingress_rules[count.index].cidr_block]

  allow {
    protocol              = var.private_ingress_rules[count.index].protocol == "-1" ? "all" : var.private_ingress_rules[count.index].protocol
    ports                 = var.private_ingress_rules[count.index].protocol == "-1" ? null : [ var.private_ingress_rules[count.index].from_port]
  }
}

resource "google_compute_firewall" "egress_rules" {
  count                   = length(var.private_egress_rules)
  name                    = "${var.environment}-${var.deployment}-${var.role}-egress-rule"
  description             = "${var.environment}-${var.deployment}-${var.role}-egress-rule"
  direction               = "EGRESS"
  network                 = google_compute_network.network.name
  project                 = var.gcp_project_id
  destination_ranges      = [var.private_egress_rules[count.index].cidr_block]

  allow {
    protocol              = var.private_egress_rules[count.index].protocol == "-1" ? "all" : var.private_egress_rules[count.index].protocol
    ports                 = var.private_egress_rules[count.index].protocol == "-1" ? null : [ var.private_egress_rules[count.index].from_port]
  }
}