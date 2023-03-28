data "aws_availability_zones" "available" {}

# private resources 
resource "aws_vpc" "private" {
  cidr_block = var.private_network
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "private-vpc-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
    role = var.role
    public = "false"
  }
}


resource "aws_internet_gateway" "private" {
  vpc_id = aws_vpc.private.id

  tags = {
    Name = "private-nat-internet-gw-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
  }
}

resource "aws_eip" "nat_gateway" {
  vpc = true
}

resource "aws_nat_gateway" "private" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.nat_gateway.id

  tags = {
    Name = "private-nat-gw-${var.environment}-${var.deployment}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.private]
}

resource "aws_subnet" "nat_gateway" {
  vpc_id            = aws_vpc.private.id
  cidr_block        = var.private_nat_subnet
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "private-nat-gw-subnet-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
  }
}

resource "aws_route_table" "nat_gateway" {
  vpc_id = aws_vpc.private.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.private.id
  }
}

resource "aws_route_table_association" "nat_gateway" {
  subnet_id = aws_subnet.nat_gateway.id
  route_table_id = aws_route_table.nat_gateway.id
}

resource "aws_subnet" "private" {
    vpc_id            = aws_vpc.private.id
    cidr_block        = var.private_subnet
    availability_zone = data.aws_availability_zones.available.names[0]
    
    tags = {
        Name = "private-subnet-${var.environment}-${var.deployment}"
        environment = var.environment
        deployment = var.deployment
        role = var.role
        public = "false"
    }
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.private.id

    route {
        cidr_block = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.private.id
    }

    tags = {
        Name = "default-private-nat-gw-route-${var.environment}-${var.deployment}"
        environment = var.environment
        deployment = var.deployment
    }
}

resource "aws_route_table_association" "private" {
  subnet_id = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

resource "aws_security_group" "private" {
  name = "private-security-group-${var.environment}-${var.deployment}"
  vpc_id = aws_vpc.private.id

  tags = {
    Name = "private-security-group-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
    role = var.role
    public = "false"
  }
}

resource "aws_security_group_rule" "private_ingress_rules" {
  count = length(var.private_ingress_rules)

  type              = "ingress"
  from_port         = var.private_ingress_rules[count.index].from_port
  to_port           = var.private_ingress_rules[count.index].to_port
  protocol          = var.private_ingress_rules[count.index].protocol
  cidr_blocks       = [var.private_ingress_rules[count.index].cidr_block]
  description       = var.private_ingress_rules[count.index].description
  security_group_id = aws_security_group.private.id
}

resource "aws_security_group_rule" "private_egress_rules" {
  count = length(var.private_egress_rules)

  type              = "egress"
  from_port         = var.private_egress_rules[count.index].from_port
  to_port           = var.private_egress_rules[count.index].to_port
  protocol          = var.private_egress_rules[count.index].protocol
  cidr_blocks       = [var.private_egress_rules[count.index].cidr_block]
  description       = var.private_egress_rules[count.index].description
  security_group_id = aws_security_group.private.id
}

resource "aws_security_group_rule" "private_allow_egress_inter_security_group" {
  count = var.trust_security_group == true ? 1 : 0
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  description       = "allow all egress inter security group"
  security_group_id = aws_security_group.private.id
}

resource "aws_security_group_rule" "private_allow_ingress_inter_security_group" {
  count = var.trust_security_group == true ? 1 : 0
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  description       = "allow all ingress inter security group"
  security_group_id = aws_security_group.private.id
}

