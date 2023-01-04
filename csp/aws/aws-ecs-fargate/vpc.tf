resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "ecs-${var.app}-${var.environment}-main-igw"
    }
}

resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "ecs-${var.app}-${var.environment}-main-vpc"
    }
}

resource "aws_default_route_table" "example" {
  default_route_table_id = aws_vpc.main.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "ecs-${var.app}-${var.environment}-default-route"
  }
}

resource "aws_subnet" "main-subnet-public-1" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1a"
    tags = {
        Name = "ecs-${var.app}-${var.environment}-main-alb-subnet-public-1"
        Tier = "Public"
    }
}

resource "aws_subnet" "main-subnet-public-2" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "us-east-1b"
    tags = {
        Name = "ecs-${var.app}-${var.environment}-main-alb-subnet-public-2"
        Tier = "Public"
    }
}


data "aws_subnets" "main" {
  filter {
    name   = "vpc-id"
    values = [aws_vpc.main.id]
  }
#   tags = {
#     Tier = "Public"
#   }
}


resource "aws_route_table_association" "main-public-subnet-route-table-association-1"{
    subnet_id = aws_subnet.main-subnet-public-1.id
    route_table_id = aws_vpc.main.default_route_table_id
}

resource "aws_route_table_association" "main-public-subnet-route-table-association-2"{
    subnet_id = aws_subnet.main-subnet-public-2.id
    route_table_id = aws_vpc.main.default_route_table_id
}

resource "aws_security_group" "alb_security_group" {
    vpc_id = aws_vpc.main.id
    
    egress {
        from_port = 0
        to_port = 0
        protocol = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        from_port = 5000
        to_port = 5000
        protocol = "tcp"
        // This means, all ip address are allowed to ssh ! 
        // Do not do it in the production. 
        // Put your office or home address in it!
        cidr_blocks = [
            "50.98.22.145/32", # external trusted ip
            "10.0.1.0/24",      # internal subnet 1
            "10.0.2.0/24"       # internal subnet 2
        ]
        // cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
        Name = "ecs-${var.app}-${var.environment}-main-alb-security-group"
    }
}