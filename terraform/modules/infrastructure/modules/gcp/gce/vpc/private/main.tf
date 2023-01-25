resource "google_compute_router" "router" {
  name                                  = "main-${var.environment}-${var.deployment}-private-router"
  region  = google_compute_subnetwork.subnetwork.region
  network = google_compute_network.vpc_network.id
}

resource "google_compute_router_nat" "nat" {
    name                                = "main-${var.environment}-${var.deployment}-private-router-nat"
    router                              = google_compute_router.router.name
    region                              = google_compute_router.router.region
    nat_ip_allocate_option              = "AUTO_ONLY"
    source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"

    log_config {
    enable                              = true
        filter                          = "ERRORS_ONLY"
    }
}

resource "google_compute_network" "vpc_network" {
    name                                = "main-${var.environment}-${var.deployment}-private-vpc"
    auto_create_subnetworks             = "false"
    project                             = var.gcp_project_id
}

resource "google_compute_subnetwork" "subnetwork" {
    name                                = "main-${var.environment}-${var.deployment}-private-subnetwork"
    ip_cidr_range                       = var.private_network
    region                              = var.gcp_location
    network                             = google_compute_network.vpc_network.name
    purpose                             = "PRIVATE"
  
    secondary_ip_range {
        range_name                      = "main-${var.environment}-${var.deployment}-private-secondary-ip-range"
        ip_cidr_range                   = var.private_subnet
    }

    depends_on = [
        google_compute_network.vpc_network,
    ]
}

resource "google_compute_address" "nat-ip" {
    name                                = "main-${var.environment}-${var.deployment}-private-nat-ip"
    project                             = var.gcp_project_id
    region                              = var.gcp_location
}

resource "google_compute_firewall" "ingress_rules" {
  count                   = length(var.private_ingress_rules)
  name                    = "main-${var.environment}-${var.deployment}-private-ingress-rule"
  description             = "main-${var.environment}-${var.deployment}-private-ingress-rule"
  direction               = "INGRESS"
  network                 = google_compute_network.vpc_network.name
  project                 = var.gcp_project_id
  source_ranges           = [var.private_ingress_rules[count.index].cidr_block]

  allow {
    protocol              = var.private_ingress_rules[count.index].protocol == "-1" ? "all" : var.private_ingress_rules[count.index].protocol
    ports                 = [var.private_ingress_rules[count.index].from_port]
  }
}

resource "google_compute_firewall" "egress_rules" {
  count                   = length(var.private_egress_rules)
  name                    = "main-${var.environment}-${var.deployment}-private-egress-rule"
  description             = "main-${var.environment}-${var.deployment}-private-egress-rule"
  direction               = "EGRESS"
  network                 = google_compute_network.vpc_network.name
  project                 = var.gcp_project_id
  destination_ranges      = [var.private_egress_rules[count.index].cidr_block]

  allow {
    protocol              = var.private_egress_rules[count.index].protocol == "-1" ? "all" : var.private_egress_rules[count.index].protocol
    ports                 = [var.private_egress_rules[count.index].from_port]
  }
}