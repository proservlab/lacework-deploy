data "aws_ami" "ubuntu" {
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

module "vpc" {
  source = "./vpc"
  name = "main"
  environment = var.environment

  private_ingress_rules = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "allow ssh inbound"
      }
  ]

  private_egress_rules = [
      {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_block = "0.0.0.0/0"
          description = "allow all outbound"
      }
  ]
  
  public_ingress_rules = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_block  = "0.0.0.0/0"
        description = "allow ssh inbound"
      }
  ]

  public_egress_rules = [
      {
          from_port = 0
          to_port = 0
          protocol = "-1"
          cidr_block = "0.0.0.0/0"
          description = "allow all outbound"
      }
  ]
  
}

# ssm profile
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

resource "aws_iam_policy" "ec2-describe-tags" {
  name        = "ec2_describe_tags"
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
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2-instance-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = aws_iam_policy.ec2-describe-tags.arn
}

# private instance
resource "aws_instance" "ubuntu" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ec2-iam-profile.name
  subnet_id = module.vpc.private_subnet.id
  vpc_security_group_ids = [ module.vpc.private_sg.id ]
  
  tags = {
    Name = "ec2-private"
    Environment = var.environment
  }

  depends_on = [module.vpc]
}

# public instance
resource "aws_instance" "ubuntu-unprotected" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  
  iam_instance_profile = aws_iam_instance_profile.ec2-iam-profile.name
  subnet_id = module.vpc.public_subnet.id
  vpc_security_group_ids = [ module.vpc.public_sg.id ]
  
  tags = {
    Name = "ec2-public"
    Environment = var.environment
  }

  depends_on = [module.vpc]
}

resource "aws_instance" "ubuntu-unprotected-2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  
  iam_instance_profile = aws_iam_instance_profile.ec2-iam-profile.name
  subnet_id = module.vpc.public_subnet.id
  vpc_security_group_ids = [ module.vpc.public_sg.id ]
  
  tags = {
    Name = "ec2-public-2"
    Environment = var.environment
  }

  depends_on = [module.vpc]
}

resource "aws_instance" "ubuntu-unprotected-3" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  
  iam_instance_profile = aws_iam_instance_profile.ec2-iam-profile.name
  subnet_id = module.vpc.public_subnet.id
  vpc_security_group_ids = [ module.vpc.public_sg.id ]
  
  tags = {
    Name = "ec2-public-3"
    NoLacework = "true"
  }

  depends_on = [module.vpc]
}