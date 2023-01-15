# app lb security group
resource "aws_security_group" "app_lb" {
  name        = "app_lb"
  description = "Allow inbound traffic from trusted source"
  vpc_id      = var.cluster_vpc_id

  ingress {
    description      = "Allow 1024-65535"
    from_port        = 1024
    to_port          = 65535
    protocol         = "tcp"
    cidr_blocks      =  flatten([
      var.trusted_attacker_source,
      var.trusted_workstation_source,
      var.additional_trusted_sources,
    ])
  }

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
  from_port         = 8002
  to_port           = 8002
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all tcp inbound from to service port"
  security_group_id = aws_security_group.app_lb.id
}

resource "aws_security_group_rule" "target_ingress_service_port_vote" {
  type              = "ingress"
  from_port         = 8001
  to_port           = 8001
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all tcp inbound from to service port"
  security_group_id = aws_security_group.app_lb.id
}