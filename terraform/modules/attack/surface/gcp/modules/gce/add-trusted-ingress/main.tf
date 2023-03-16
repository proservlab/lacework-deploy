resource "google_compute_firewall" "attacker_ingress_rules" {
  count                   = length(var.trusted_attacker_source)
  name                    = "${var.environment}-${var.deployment}-public-attacker-ingress-rule-${count.index}"
  description             = "${var.environment}-${var.deployment}-public-attacker-ingress-rule-${count.index}"
  direction               = "INGRESS"
  network                 = var.network
  project                 = var.gcp_project_id
  source_ranges           = [var.trusted_attacker_source[count.index]]

  allow {
    protocol              = "tcp"
    ports                 = [ "${var.trusted_tcp_ports.from_port}-${var.trusted_tcp_ports.to_port}" ]
  }
}

resource "google_compute_firewall" "target_ingress_rules" {
  count                   = length(var.trusted_target_source)
  name                    = "${var.environment}-${var.deployment}-public-target-ingress-rule-${count.index}"
  description             = "${var.environment}-${var.deployment}-public-target-ingress-rule-${count.index}"
  direction               = "INGRESS"
  network                 = var.network
  project                 = var.gcp_project_id
  source_ranges           = [var.trusted_target_source[count.index]]

  allow {
    protocol              = "tcp"
    ports                 = [ "${var.trusted_tcp_ports.from_port}-${var.trusted_tcp_ports.to_port}" ]
  }
}

resource "google_compute_firewall" "workstation_ingress_rules" {
  count                   = length(var.trusted_workstation_source) > 0 ?  1 : 0
  name                    = "${var.environment}-${var.deployment}-public-workstation-ingress-rule-${count.index}"
  description             = "${var.environment}-${var.deployment}-public-workstation-ingress-rule-${count.index}"
  direction               = "INGRESS"
  network                 = var.network
  project                 = var.gcp_project_id
  source_ranges           = var.trusted_workstation_source

  allow {
    protocol              = "tcp"
    ports                 = [ "${var.trusted_tcp_ports.from_port}-${var.trusted_tcp_ports.to_port}" ]
  }
}