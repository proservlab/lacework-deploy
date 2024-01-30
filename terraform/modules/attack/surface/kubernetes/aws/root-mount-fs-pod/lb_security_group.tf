# app lb security group
resource "aws_security_group" "this" {
  name        = "${local.app_name}-app-lb-sg-${var.environment}-${var.deployment}"
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
    Name = "${local.app_name}-app-lb-sg-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
  }
}

resource "aws_security_group_rule" "attacker_ingress_rules" {
  type              = "ingress"
  from_port         = var.service_port
  to_port           = var.service_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
    var.trusted_attacker_source
  ]))
  security_group_id = aws_security_group.this.id

  timeouts {
    create = "10m"
  }
}

resource "aws_security_group_rule" "target_ingress_rules" {
  type              = "ingress"
  from_port         = var.service_port
  to_port           = var.service_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
    var.trusted_target_source
  ]))
  description       = "Allow all tcp inbound from workstation, attacker and target public ips"
  security_group_id = aws_security_group.this.id

  timeouts {
    create = "10m"
  }
}

resource "aws_security_group_rule" "workstation_ingress_rules" {
  type              = "ingress"
  from_port         = var.service_port
  to_port           = var.service_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
    var.trusted_workstation_source
  ]))
  description       = "Allow all tcp inbound from workstation, attacker and target public ips"
  security_group_id = aws_security_group.this.id

  timeouts {
    create = "10m"
  }
}

resource "aws_security_group_rule" "additional_sources_ingress_rules" {
  type              = "ingress"
  from_port         = var.service_port
  to_port           = var.service_port
  protocol          = "tcp"
  cidr_blocks       = sort(flatten([
    var.additional_trusted_sources
  ]))
  description       = "Allow all tcp inbound from workstation, attacker and target public ips"
  security_group_id = aws_security_group.this.id

  timeouts {
    create = "10m"
  }
}