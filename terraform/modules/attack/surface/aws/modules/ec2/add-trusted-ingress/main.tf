resource "aws_security_group_rule" "attacker_ingress_rules" {
  for_each = toset(sort(flatten([
    var.trusted_attacker_source,
    var.trusted_target_source,
    var.trusted_workstation_source,
    var.additional_trusted_sources
  ])))
  type              = "ingress"
  from_port         = var.trusted_tcp_ports.from_port
  to_port           = var.trusted_tcp_ports.to_port
  protocol          = "tcp"
  cidr_blocks       = [each.value]
  description       = "Allow all tcp inbound from workstation, attacker and target public ips"
  security_group_id = var.security_group_id

  timeouts {
    create = "10m"
  }
}