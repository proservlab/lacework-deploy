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
}

resource "aws_vpc" "cluster" {
  cidr_block = local.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = tomap({
    "Name"                                      = "terraform-eks-${var.environment}-node",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  })
}

resource "aws_subnet" "cluster" {
  count = 2

  availability_zone       = data.aws_availability_zones.available.names[count.index]
  cidr_block              = cidrsubnet(local.vpc_cidr,8,count.index)
  map_public_ip_on_launch = true
  vpc_id                  = aws_vpc.cluster.id

  tags = tomap({
    "Name"                                      = "terraform-eks-${var.environment}-node",
    "kubernetes.io/cluster/${var.cluster_name}" = "shared",
  })
}

resource "aws_internet_gateway" "cluster" {
  vpc_id = aws_vpc.cluster.id

  tags = {
    Name = "terraform-eks-${var.environment}"
  }
}

resource "aws_route_table" "cluster" {
  vpc_id = aws_vpc.cluster.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cluster.id
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

  name      = "terraform-eks-${var.environment}-vpcep-sg"
  vpc_id    = aws_vpc.cluster.id
  tags      = {
                Name = "terraform-eks-${var.environment}-vpcep-sg"
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
                Name = "terraform-eks-${var.environment}-vpcepi-${each.key}"
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
                Name = "terraform-eks-${var.environment}-vpcepg-${each.key}"
              }
}
