#
# VPC Resources
#  * VPC
#  * Subnets
#  * Internet Gateway
#  * Route Table
#

locals {
  vpc_cidr = "10.0.0.0/16"
  vpc_interface_endpoints = toset(["autoscaling", "ecr.api", "ecr.dkr", "ec2", "ec2messages", "elasticloadbalancing", "sts", "kms", "logs", "ssm", "ssmmessages"])
  vpc_gateway_endpoints = toset(["s3"])

  cluster_subnet_count = 2
}

resource "aws_vpc" "cluster" {
  cidr_block = local.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = tomap({
    "Name"                                      = "terraform-eks-${var.environment}-${var.deployment}-node",
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}-${var.deployment}" = "shared",
    "environment" = var.environment,
    "deployment" = var.deployment
  })
}

resource "aws_subnet" "cluster" {
  count = local.cluster_subnet_count

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.vpc_cidr,8,count.index)
  vpc_id                  = aws_vpc.cluster.id
  map_public_ip_on_launch = false

  tags = tomap({
    "Name"                                      = "terraform-eks-${var.environment}-${var.deployment}-node",
    "kubernetes.io/cluster/${var.cluster_name}-${var.environment}-${var.deployment}" = "shared",
    # "kubernetes.io/role/${count.index==0?"elb":"internal-elb"}" = "1",
    "kubernetes.io/role/internal-elb" = "1",
    "environment" = var.environment,
    "deployment" = var.deployment
  })
}

resource "aws_internet_gateway" "private" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name = "eks-private-nat-internet-gw-${var.cluster_name}-${var.environment}-${var.deployment}"
  }
}

resource "aws_eip" "nat_gateway" {
  domain = "vpc"
  tags = {
    Name = "eks-private-nat-eip-${var.cluster_name}-${var.environment}-${var.deployment}"
  }
}

resource "aws_nat_gateway" "private" {
  allocation_id = aws_eip.nat_gateway.id
  subnet_id     = aws_subnet.nat_gateway.id

  tags = {
    Name = "eks-private-nat-gw-${var.cluster_name}-${var.environment}-${var.deployment}"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.private]
}

resource "aws_subnet" "nat_gateway" {
  vpc_id            = aws_vpc.cluster.id
  # assign the next /24 subnet to the nat gateway
  cidr_block        = cidrsubnet(local.vpc_cidr,8,local.cluster_subnet_count)
  availability_zone = data.aws_availability_zones.available.names[0]
  
  tags = {
    Name = "eks-private-nat-gw-subnet-${var.cluster_name}-${var.environment}-${var.deployment}"
    environment = var.environment
    deployment = var.deployment
  }
}

# route nat gateway through internet gateway
resource "aws_route_table" "nat_gateway" {
  vpc_id = aws_vpc.cluster.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.private.id
  }
}

resource "aws_route_table_association" "nat_gateway" {
  subnet_id = aws_subnet.nat_gateway.id
  route_table_id = aws_route_table.nat_gateway.id
}

# route nodes through nat gateway
resource "aws_route_table" "cluster" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    # gateway_id = aws_internet_gateway.cluster.id
    nat_gateway_id = aws_nat_gateway.private.id
  }
}

resource "aws_route_table_association" "cluster" {
  count = 2

  subnet_id      = aws_subnet.cluster[count.index].id
  route_table_id = aws_route_table.cluster.id
}

# VPC Endpoints Security Group
resource "aws_security_group" "cluster_vpc_endpoint" {
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [local.vpc_cidr]
  }

  name      = "eks-vpcep-sg-${var.cluster_name}-${var.environment}-${var.deployment}"
  vpc_id    = aws_vpc.cluster.id
  tags      = {
                Name = "eks-vpcep-sg-${var.cluster_name}-${var.environment}-${var.deployment}"
              }
}

# SSM VPC Interface Endpoints

data "aws_vpc_endpoint_service" "vpc_interface_endpoint" {
  for_each = local.vpc_interface_endpoints
  service      = each.key
  service_type = "Interface"
}

resource "aws_vpc_endpoint" "vpc_interface_endpoint" {
  for_each = local.vpc_interface_endpoints
  vpc_id              = aws_vpc.cluster.id

  private_dns_enabled = true
  service_name        = data.aws_vpc_endpoint_service.vpc_interface_endpoint[each.key].service_name
  vpc_endpoint_type   = data.aws_vpc_endpoint_service.vpc_interface_endpoint[each.key].service_type
  security_group_ids = [
    aws_security_group.cluster_vpc_endpoint.id,
  ]
  tags      = {
                Name = "eks-vpcepi-${each.key}-${var.cluster_name}-${var.environment}-${var.deployment}"
              }
}

resource "aws_vpc_endpoint_subnet_association" "vpc_interface_endpoint_subnet_1" {
  for_each = local.vpc_interface_endpoints
  vpc_endpoint_id = aws_vpc_endpoint.vpc_interface_endpoint[each.key].id
  subnet_id       = aws_subnet.cluster[0].id
}

resource "aws_vpc_endpoint_subnet_association" "vpc_interface_endpoint_subnet_2" {
  for_each = local.vpc_interface_endpoints
  vpc_endpoint_id = aws_vpc_endpoint.vpc_interface_endpoint[each.key].id
  subnet_id       = aws_subnet.cluster[1].id
}

# SSM VPC GATEWAY Endpoints

data "aws_vpc_endpoint_service" "vpc_gateway_endpoint" {
  for_each = local.vpc_gateway_endpoints
  service      = each.key
  service_type = "Gateway"
}

resource "aws_vpc_endpoint" "vpc_gateway_endpoint" {
  for_each = local.vpc_gateway_endpoints
  vpc_id              = aws_vpc.cluster.id
  service_name        = data.aws_vpc_endpoint_service.vpc_gateway_endpoint[each.key].service_name
  vpc_endpoint_type   = data.aws_vpc_endpoint_service.vpc_gateway_endpoint[each.key].service_type
  tags      = {
                Name = "eks-vpcepg-${each.key}-${var.cluster_name}-${var.environment}-${var.deployment}"
              }
}
