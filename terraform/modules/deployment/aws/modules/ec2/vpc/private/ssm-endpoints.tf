locals {
  vpc_interface_endpoints = toset(["ec2", "ec2messages", "ssm", "ssmmessages"])
  vpc_gateway_endpoints = toset(["s3"])
}

# VPC ENDPOINT SECURITY GROUP

resource "aws_security_group" "vpc_endpoint" {
  name        = "private-vpcep-sg-${var.environment}-${var.deployment}"
  description = "Allow TLS inbound To AWS Systems Manager Session Manager"
  vpc_id      = aws_vpc.private.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.private.cidr_block]
  }

  egress {
    description = "Allow All Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "private-vpcep-sg-${var.environment}-${var.deployment}"
  }
}

# VPC INTERFACE ENDPOINT
data "aws_vpc_endpoint_service" "vpc_interface_endpoint" {
  for_each = local.vpc_interface_endpoints
  service = each.key
  service_type = "Interface"
}

resource "aws_vpc_endpoint" "vpc_interface_endpoint" {
  for_each = local.vpc_interface_endpoints
  vpc_id          = aws_vpc.private.id
  service_name    = data.aws_vpc_endpoint_service.vpc_interface_endpoint[each.key].service_name
  subnet_ids      = [ aws_subnet.private.id ]

  vpc_endpoint_type = data.aws_vpc_endpoint_service.vpc_interface_endpoint[each.key].service_type

  security_group_ids = [
    aws_security_group.vpc_endpoint.id,
  ]

  private_dns_enabled = true

  tags = {
    Name = "private-vpcepi-${each.key}-${var.environment}-${var.deployment}"
  }
}

# VPC GATEWAY ENDPOINT
data "aws_vpc_endpoint_service" "vpc_gateway_endpoint" {
  for_each = local.vpc_gateway_endpoints
  service = each.key
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "vpc_gateway_endpoint" {
  for_each = local.vpc_gateway_endpoints
  vpc_id          = aws_vpc.private.id
  service_name    = data.aws_vpc_endpoint_service.vpc_gateway_endpoint[each.key].service_name
  vpc_endpoint_type = data.aws_vpc_endpoint_service.vpc_gateway_endpoint[each.key].service_type
  tags = {
    Name = "private-vpcepg-${each.key}"
  }
}