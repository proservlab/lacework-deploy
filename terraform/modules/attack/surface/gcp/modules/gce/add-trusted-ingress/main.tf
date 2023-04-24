resource "google_compute_firewall" "public-ingress_rules" {
  name                    = "${var.environment}-${var.deployment}-public-ingress-rule"
  description             = "${var.environment}-${var.deployment}-public-ingress-rule"
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