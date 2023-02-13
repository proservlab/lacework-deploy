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

# resource "aws_security_group_rule" "attacker_ingress_rules" {
#   count = length(var.trusted_attacker_source) > 0 ?  1 : 0

#   type              = "ingress"
#   from_port         = var.trusted_tcp_ports.from_port
#   to_port           = var.trusted_tcp_ports.to_port
#   protocol          = "tcp"
#   cidr_blocks       = var.trusted_attacker_source
#   description       = "Allow all tcp inbound from attacker public ips"
#   security_group_id = var.security_group_id
# }

# resource "aws_security_group_rule" "target_ingress_rules" {
#   count = length(var.trusted_target_source) > 0 ?  1 : 0

#   type              = "ingress"
#   from_port         = var.trusted_tcp_ports.from_port
#   to_port           = var.trusted_tcp_ports.to_port
#   protocol          = "tcp"
#   cidr_blocks       = var.trusted_target_source
#   description       = "Allow all tcp inbound from target public ips"
#   security_group_id = var.security_group_id
# }

# resource "aws_security_group_rule" "workstation_ingress_rules" {
#   count = length(var.trusted_workstation_source) > 0 ?  1 : 0

#   type              = "ingress"
#   from_port         = var.trusted_tcp_ports.from_port
#   to_port           = var.trusted_tcp_ports.to_port
#   protocol          = "tcp"
#   cidr_blocks       = var.trusted_workstation_source
#   description       = "Allow all tcp inbound from workstation public ips"
#   security_group_id = var.security_group_id
# }

# resource "aws_security_group_rule" "additional_ingress_rules" {
#   count = length(var.additional_trusted_sources) > 0 ?  1 : 0

#   type              = "ingress"
#   from_port         = var.trusted_tcp_ports.from_port
#   to_port           = var.trusted_tcp_ports.to_port
#   protocol          = "tcp"
#   cidr_blocks       = var.additional_trusted_sources
#   description       = "Allow all tcp inbound from additional sources public ips"
#   security_group_id = var.security_group_id
# }