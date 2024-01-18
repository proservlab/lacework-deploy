resource "random_string" "this" {
    length            = 4
    special           = false
    upper             = false
    lower             = true
    numeric           = true
}

resource "google_compute_firewall" "public-ingress_rules" {
  name                    = "${var.environment}-${var.deployment}-public-${var.role}-ingress-rule-${random_string.this.result}"
  description             = "${var.environment}-${var.deployment}-public-${var.role}-ingress-rule"
  direction               = "INGRESS"
  network                 = var.network
  project                 = var.gcp_project_id
  source_ranges           = flatten([
                                var.trusted_attacker_source,
                                var.trusted_target_source,
                                var.trusted_workstation_source
                            ])

  allow {
    protocol              = "tcp"
    ports                 = [ "${var.trusted_tcp_ports.from_port}-${var.trusted_tcp_ports.to_port}" ]
  }
}