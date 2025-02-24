data "aws_security_group" "this" {
  id = var.security_group_id
}

resource "aws_security_group_rule" "attacker_ingress_rules" {
  count = var.trusted_attacker_source_enabled == true ? 1 : 0
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
    var.trusted_attacker_source
  ]))
  description       = "Allow all tcp inbound from workstation, attacker and target public ips"
  security_group_id = data.aws_security_group.this.id

  timeouts {
    create = "10m"
  }
}

resource "aws_security_group_rule" "target_ingress_rules" {
  count = var.trusted_target_source_enabled == true ? 1 : 0
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
    var.trusted_target_source
  ]))
  description       = "Allow all tcp inbound from workstation, attacker and target public ips"
  security_group_id = data.aws_security_group.this.id

  timeouts {
    create = "10m"
  }
}

resource "aws_security_group_rule" "workstation_ingress_rules" {
  count = var.trusted_workstation_source_enabled == true ? 1 : 0
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
    var.trusted_workstation_source
  ]))
  description       = "Allow all tcp inbound from workstation, attacker and target public ips"
  security_group_id = data.aws_security_group.this.id

  timeouts {
    create = "10m"
  }
}

resource "aws_security_group_rule" "additional_sources_ingress_rules" {
  count = var.additional_trusted_sources_enabled == true ? 1 : 0
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
    var.additional_trusted_sources
  ]))
  description       = "Allow all tcp inbound from workstation, attacker and target public ips"
  security_group_id = data.aws_security_group.this.id

  timeouts {
    create = "10m"
  }
}