resource "aws_security_group_rule" "attacker_ingress_rules" {
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = var.trusted_attacker_source
  description       = "Allow all tcp inbound from attacker public ips"
  security_group_id = var.security_group_id
}

resource "aws_security_group_rule" "target_ingress_rules" {
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = var.trusted_target_source
  description       = "Allow all tcp inbound from target public ips"
  security_group_id = var.security_group_id
}

resource "aws_security_group_rule" "workstation_ingress_rules" {
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = var.trusted_workstation_source
  description       = "Allow all tcp inbound from workstation public ips"
  security_group_id = var.security_group_id
}

resource "aws_security_group_rule" "additional_ingress_rules" {
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = var.additional_trusted_sources
  description       = "Allow all tcp inbound from additional sources public ips"
  security_group_id = var.security_group_id
}