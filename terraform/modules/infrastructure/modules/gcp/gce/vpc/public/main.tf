resource "google_compute_network" "vpc_network" {
  name                                  = "main-${var.environment}-${var.deployment}-public-vpc"
  auto_create_subnetworks               = "false"
  project                               = var.gcp_project_id
}

resource "google_compute_subnetwork" "subnetwork" {
  name                                  = "main-${var.environment}-${var.deployment}-public-subnetwork"
  ip_cidr_range                         = var.public_subnet
  region                                = var.gcp_location
  project                               = var.gcp_project_id
  network                               = google_compute_network.vpc_network.name
  purpose                               = "PUBLIC"

  # secondary_ip_range {
  #   range_name                          = "main-${var.environment}-${var.deployment}-public-secondary-ip-range"
  #   ip_cidr_range                       = var.public_subnet
  # }
  
  depends_on = [
    google_compute_network.vpc_network,
  ]
}

resource "google_compute_firewall" "ingress_rules" {
  count                   = length(var.public_ingress_rules)
  name                    = "main-${var.environment}-${var.deployment}-public-ingress-rule"
  description             = "main-${var.environment}-${var.deployment}-public-ingress-rule"
  direction               = "INGRESS"
  network                 = google_compute_network.vpc_network.name
  project                 = var.gcp_project_id
  source_ranges           = [var.public_ingress_rules[count.index].cidr_block]

  allow {
    protocol              = var.public_ingress_rules[count.index].protocol == "-1" ? "all" : var.public_ingress_rules[count.index].protocol
    ports                 = var.public_ingress_rules[count.index].protocol == "-1" ? null : [ var.public_ingress_rules[count.index].from_port]
  }
}

resource "google_compute_firewall" "egress_rules" {
  count                   = length(var.public_egress_rules)
  name                    = "main-${var.environment}-${var.deployment}-public-egress-rule"
  description             = "main-${var.environment}-${var.deployment}-public-egress-rule"
  direction               = "EGRESS"
  network                 = google_compute_network.vpc_network.name
  project                 = var.gcp_project_id
  destination_ranges      = [var.public_egress_rules[count.index].cidr_block]

  allow {
    protocol              = var.public_egress_rules[count.index].protocol == "-1" ? "all" : var.public_egress_rules[count.index].protocol
    ports                 = var.public_egress_rules[count.index].protocol == "-1" ? null : [ var.public_egress_rules[count.index].from_port]
  }
}