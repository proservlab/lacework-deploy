terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

locals {
    region          = var.region
}

data "aws_availability_zones" "available" {}
data "aws_caller_identity" "current" {}

resource "aws_vpc" "public" {
  cidr_block = "172.20.0.0/16"
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
    cidr_block        = "172.20.10.0/24"
    availability_zone = data.aws_availability_zones.available.names[0]
    
    map_public_ip_on_launch = true
    
    tags = {
        Name = "${var.name}-public-subnet"
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

resource "aws_security_group" "miner" {
  name   = "miner-sg"
  vpc_id = "${aws_vpc.public.id}"

  # SSH access needed for provisioner
#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "template_file" "user_data" {
  template = "${file("${path.module}/resources/userdata.sh.tpl")}"

  vars = {
    wallet = "${var.wallet}"
    region = "${var.region}"
  }
}

data "aws_iam_instance_profile" "ssm" {
  name = "ec2_profile"
}

resource "aws_instance" "miner" {
    count           = "${var.instances}"
    ami             = "ami-0d70b8dd4ec1e2d1e"
    instance_type   = "g5.xlarge"
    
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids =    [
                                    "${aws_security_group.miner.id}"
                                ]

    user_data_base64 = base64encode(data.template_file.user_data.rendered)
    associate_public_ip_address = true
    
    # borrowed from existing environment
    iam_instance_profile = data.aws_iam_instance_profile.ssm.name

    # leverage existing ssm deployment of lacework
    tags = {
        Name = "miner-${count.index}"
        ssm_deploy_lacework = "true"
    }

    user_data_replace_on_change = true
}
