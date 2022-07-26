terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "main" {
  cidr_block = "172.16.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "tf-example"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "main" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1b"
  
  # map_public_ip_on_launch = true
  
  tags = {
    Name = "tf-example"
    Environment = var.environment
  }
}

resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main"
  }
}

resource "aws_route_table_association" "main" {
  subnet_id = aws_subnet.main.id
  route_table_id = aws_route_table.main.id
}

resource "aws_security_group" "main" {
  name = "allow-outbound-to-any"
  vpc_id = "${aws_vpc.main.id}"

  # ingress {
  #   cidr_blocks = [
  #     "0.0.0.0/0"
  #   ]
  #   from_port = 22
  #   to_port = 22
  #   protocol = "tcp"
  # }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_vpc_endpoint_service" "ssm" {
  service = "ssm"
}

resource "aws_security_group" "ssm_sg" {
  name        = "ssm-sg"
  description = "Allow TLS inbound To AWS Systems Manager Session Manager"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTPS from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.main.cidr_block]
  }

  egress {
    description = "Allow All Egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "main"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id          = aws_vpc.main.id
  service_name    = data.aws_vpc_endpoint_service.ssm.service_name
  subnet_ids      = [ aws_subnet.main.id ]

  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssm_sg.id,
  ]

  private_dns_enabled = true

  tags = {
    Name = "main-ssm-endpoint"
  }
}

resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2-iam-profile.name
  subnet_id = aws_subnet.main.id
  security_groups = [ aws_security_group.main.id ]
  
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_iam_instance_profile" "ec2-iam-profile" {
  name = "ec2_profile"
  role = aws_iam_role.ec2-iam-role.name
}
resource "aws_iam_role" "ec2-iam-role" {
  name        = "ec2-ssm-role"
  description = "The role for EC2 resources"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Principal": {
          "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  }
  EOF
  tags = {
    Environment = var.environment
  }
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}