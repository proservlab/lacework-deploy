# public resources
resource "aws_vpc" "public" {
  cidr_block = "172.17.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "${var.name}-public-vpc"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name = "${var.name}-public-internet-gw"
  }
}

resource "aws_subnet" "public" {
    vpc_id            = aws_vpc.public.id
    cidr_block        = "172.17.10.0/24"
    availability_zone = "us-east-1b"
    
    map_public_ip_on_launch = true
    
    tags = {
        Name = "${var.name}-public-subnet"
        Environment = var.environment
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.public.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.public.id
    }

    tags = {
        Name = "${var.name}-default-public-internet-gw-route"
    }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "public" {
  name = "${var.name}-public-security-group"
  vpc_id = "${aws_vpc.public.id}"
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