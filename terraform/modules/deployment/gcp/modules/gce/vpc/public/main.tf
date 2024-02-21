resource "google_compute_network" "network" {
  name                                  = "${var.environment}-${var.deployment}-public-${var.role}-vpc"
  auto_create_subnetworks               = "false"
  project                               = var.gcp_project_id
}

resource "google_compute_subnetwork" "subnetwork" {
  name                                  = "${var.environment}-${var.deployment}-public-${var.role}-subnetwork"
  ip_cidr_range                         = var.public_subnet
  region                                = var.gcp_location
  project                               = var.gcp_project_id
  network                               = google_compute_network.network.name

  # secondary_ip_range {
  #   range_name                          = "${var.environment}-${var.deployment}-public-${var.role}-secondary-ip-range"
  #   ip_cidr_range                       = var.public_subnet
  # }
  
  depends_on = [
    google_compute_network.network,
  ]
}

resource "google_compute_firewall" "ingress_rules" {
  count                   = length(var.public_ingress_rules)
  name                    = "${var.environment}-${var.deployment}-public-${var.role}-ingress-rule"
  description             = "${var.environment}-${var.deployment}-public-${var.role}-ingress-rule"
  direction               = "INGRESS"
  network                 = google_compute_network.network.name
  project                 = var.gcp_project_id
  source_ranges           = [var.public_ingress_rules[count.index].cidr_block]

  allow {
    protocol              = var.public_ingress_rules[count.index].protocol == "-1" ? "all" : var.public_ingress_rules[count.index].protocol
    ports                 = var.public_ingress_rules[count.index].protocol == "-1" ? null : [ var.public_ingress_rules[count.index].from_port]
  }
}

resource "google_compute_firewall" "egress_rules" {
  count                   = length(var.public_egress_rules)
  name                    = "${var.environment}-${var.deployment}-public-${var.role}-egress-rule"
  description             = "${var.environment}-${var.deployment}-public-${var.role}-egress-rule"
  direction               = "EGRESS"
  network                 = google_compute_network.network.name
  project                 = var.gcp_project_id
  destination_ranges      = [var.public_egress_rules[count.index].cidr_block]

  allow {
    protocol              = var.public_egress_rules[count.index].protocol == "-1" ? "all" : var.public_egress_rules[count.index].protocol
    ports                 = var.public_egress_rules[count.index].protocol == "-1" ? null : [ var.public_egress_rules[count.index].from_port]
  }
}

resource "google_compute_firewall" "allow_ssh" {
  name                    = "${var.environment}-${var.deployment}-${var.role}-iap-rule"
  network                 = google_compute_network.network.name
  project                 = var.gcp_project_id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # Allow SSH only from IAP
  source_ranges           = ["35.235.240.0/20"]
  target_service_accounts = [var.service_account_email]
}