data "aws_availability_zones" "available" {}

# public resources
resource "aws_vpc" "public" {
  cidr_block = var.public_network
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "public-vpc-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
    role = var.role
    public = "true"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name = "public-internet-gw-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
  }
}

resource "aws_subnet" "public" {
    vpc_id            = aws_vpc.public.id
    cidr_block        = var.public_subnet
    availability_zone = data.aws_availability_zones.available.names[0]
    
    # perfer elastic ip - so we don't change ip on reboot
    # map_public_ip_on_launch = true
    
    tags = {
        Name = "public-subnet-${var.environment}-${var.deployment}"
        environment = var.environment
        deployment = var.deployment
        role = var.role
        public = "true"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.public.id

    tags = {
        Name = "default-public-internet-gw-route-${var.environment}-${var.deployment}"
        environment = var.environment
        deployment = var.deployment
    }
}

resource "aws_route" "public" {
  route_table_id = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.public.id
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "public" {
  name = "public-security-group-${var.environment}-${var.deployment}"
  vpc_id = aws_vpc.public.id

  tags = {
    Name = "public-security-group-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
    role = var.role
    public = "true"
  }
}

resource "aws_security_group_rule" "public_ingress_rules" {
  count = length(var.public_ingress_rules)

  type              = "ingress"
  from_port         = var.public_ingress_rules[count.index].from_port
  to_port           = var.public_ingress_rules[count.index].to_port
  protocol          = var.public_ingress_rules[count.index].protocol
  cidr_blocks       = [var.public_ingress_rules[count.index].cidr_block]
  description       = var.public_ingress_rules[count.index].description
  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public_egress_rules" {
  count = length(var.public_egress_rules)

  type              = "egress"
  from_port         = var.public_egress_rules[count.index].from_port
  to_port           = var.public_egress_rules[count.index].to_port
  protocol          = var.public_egress_rules[count.index].protocol
  cidr_blocks       = [var.public_egress_rules[count.index].cidr_block]
  description       = var.public_egress_rules[count.index].description
  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public_allow_egress_inter_security_group" {
  count = var.trust_security_group == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  description       = "allow all egress inter security group"
  security_group_id = aws_security_group.public.id
}

resource "aws_security_group_rule" "public_allow_ingress_inter_security_group" {
  count = var.trust_security_group == true ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  description       = "allow all ingress inter security group"
  security_group_id = aws_security_group.public.id
}