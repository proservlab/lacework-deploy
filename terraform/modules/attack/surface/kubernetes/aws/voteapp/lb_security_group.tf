# app lb security group
resource "aws_security_group" "this" {
  name        = "app_lb"
  description = "Allow inbound traffic from trusted source"
  vpc_id      = var.cluster_vpc_id

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.app}-allow-lb-inbound"
  }
}

resource "aws_security_group_rule" "target_ingress_service_port_result" {
  type              = "ingress"
  from_port         = var.result_service_port
  to_port           = var.result_service_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
      var.trusted_attacker_source,
      var.trusted_workstation_source,
      var.additional_trusted_sources,
    ]))
  description       = "Allow all tcp inbound from to service port"
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "target_ingress_service_port_vote" {
  type              = "ingress"
  from_port         = var.vote_service_port
  to_port           = var.vote_service_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
      var.trusted_attacker_source,
      var.trusted_workstation_source,
      var.additional_trusted_sources,
    ]))
  description       = "Allow all tcp inbound from to service port"
  security_group_id = aws_security_group.this.id
}