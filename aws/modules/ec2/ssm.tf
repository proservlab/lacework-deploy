# ssm vpc endpoint
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
    Name = "main-ssm"
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
######## setup vpc endpoints for ssm ###########

# ssmmessages vpc endpoint
data "aws_vpc_endpoint_service" "ssmmessages" {
  service = "ssmmessages"
}

resource "aws_security_group" "ssmmessages_sg" {
  name        = "ssmmessages-sg"
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
    Name = "main-ssmmessages"
  }
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id          = aws_vpc.main.id
  service_name    = data.aws_vpc_endpoint_service.ssmmessages.service_name
  subnet_ids      = [ aws_subnet.main.id ]

  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ssmmessages_sg.id,
  ]

  private_dns_enabled = true

  tags = {
    Name = "main-ssmmessages-endpoint"
  }
}

# ec2 vpc endpoint
data "aws_vpc_endpoint_service" "ec2" {
  service = "ec2"
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
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
    Name = "main-ec2"
  }
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id          = aws_vpc.main.id
  service_name    = data.aws_vpc_endpoint_service.ec2.service_name
  subnet_ids      = [ aws_subnet.main.id ]

  vpc_endpoint_type = "Interface"

  security_group_ids = [
    aws_security_group.ec2_sg.id,
  ]

  private_dns_enabled = true

  tags = {
    Name = "main-ec2-endpoint"
  }
}