terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
    
  }
}

data "aws_availability_zones" "available" {}

locals {
    name = "${name}"
    instances = "${instances}"
    user_data = <<-EOT
                #!/bin/bash -x
                cd /tmp
                WALLETADDRESS="${ wallet }"
                REGION="${ region }"
                PREFERRED_SERVER="us1-etc"
                ETCMINTERTARGZ="etcminer-0.20.0-cuda-11-opencl-linux-x86_64.tar.gz"
                ETCMINERARGS="-U"
                INSTTYPE=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
                wget -O etcminer.tar.gz https://etcminer-release.s3.amazonaws.com/0.20.0/$ETCMINTERTARGZ
                tar xvfz etcminer.tar.gz
                cd etcminer
                cat > runner.sh << __EOF__
                #!/bin/bash -x
                while (true); do
                    ./etcminer $ETCMINERARGS --exit \
                    -P stratums://$WALLETADDRESS.$REGION@$PREFERRED_SERVER.ethermine.org:5555 \
                    -P stratums://$WALLETADDRESS.$REGION@us1-etc.ethermine.org:5555 \
                    -P stratums://$WALLETADDRESS.$REGION@eu1-etc.ethermine.org:5555 \
                    -P stratums://$WALLETADDRESS.$REGION@asia1-etc.ethermine.org:5555 \
                    >> /tmp/etcminer.log 2>&1
                    sleep 1
                done
                __EOF__
                chmod +x runner.sh
                nohup ./runner.sh &
                EOT
}

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
    availability_zone = data.aws_availability_zones.available.names[0]
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

# ssm profile
resource "aws_iam_instance_profile" "ec2-iam-profile" {
  name = "ec2_profile_cloudcrypto"
  role = aws_iam_role.ec2-iam-role.name
  tags = {
    environment = "cloudcrypto"
    deployment = "0"
  }
}

resource "aws_iam_role" "ec2-iam-role" {
  name        = "ec2_profile_cloudcrypto"
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
    environment = "cloudcrypto"
    deployment = "0"
  }
}

resource "aws_iam_policy" "ec2-describe-tags" {
  name        = "ec2_describe_tags_cloudcrypto"
  description = "ec2 describe tags"

  policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "DescribeTagsOnly",
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeTags"
                ],
                "Resource": "*"
            }
        ]
    }
  )
  tags = {
    environment = "cloudcrypto"
    deployment = "0"
  }
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2-instance-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = aws_iam_policy.ec2-describe-tags.arn
}

resource "aws_instance" "miner" {
    count           = local.instances
    ami             = "ami-0d70b8dd4ec1e2d1e"
    instance_type   = "g5.xlarge"
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids =    [aws_security_group.miner.id]
    user_data_base64 = base64encode(local.user_data)
    associate_public_ip_address = true
    iam_instance_profile = aws_iam_instance_profile.ec2-iam-profile.name
    tags = {
        Name = "$${local.name}-$${count.index}"
        ssm_deploy_lacework = "true"
    }
    user_data_replace_on_change = true
}
