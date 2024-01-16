data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

resource "random_string" "root_db_password" {
    length            = 16
    special           = false
    upper             = true
    lower             = true
    numeric           = true
}

locals {
  init_db_username = var.root_db_username
  init_db_password = random_string.root_db_password.result
  
  database_name = var.database_name
  database_port = var.database_port

  subnets_cidrs = [
      cidrsubnet(var.vpc_subnet,8,200),
      cidrsubnet(var.vpc_subnet,8,210)
  ]

  availability_zones = [
      data.aws_availability_zones.available.names[0],
      data.aws_availability_zones.available.names[1]
  ]
  

}

data "aws_vpc" "database" {
  id = data.aws_vpc.database.id
}

data "aws_security_group" "trusted" {
  id = data.aws_security_group.trusted.id
}

resource "aws_route_table" "database" {
    vpc_id = data.aws_vpc.database.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.igw_id
    }

    tags = {
        Name = "ec2db-internet-gw-route-${var.environment}-${var.deployment}"
        deployment = var.deployment
        environment = var.environment
    }

    depends_on = [  
      data.aws_vpc.database
    ]
}

resource "aws_route_table_association" "database" {
  subnet_id = aws_subnet.database.id
  route_table_id = aws_route_table.database.id

  depends_on = [  
    data.aws_vpc.database
  ]
}

resource "aws_route_table_association" "database2" {
  subnet_id = aws_subnet.database2.id
  route_table_id = aws_route_table.database.id

  depends_on = [  
    data.aws_vpc.database
  ]
}

resource "aws_subnet" "database" {
  vpc_id                  = data.aws_vpc.database.id
  cidr_block              = local.subnets_cidrs[0]
  availability_zone       = local.availability_zones[0]

  tags = {
    Name        = "db-subnet-${var.environment}-${var.deployment}-${local.availability_zones[0]}"
    environment = var.environment
    deployment = var.deployment
  }

  depends_on = [ 
    data.aws_vpc.database
  ]
}

resource "aws_subnet" "database2" {
  vpc_id                  = data.aws_vpc.database.id
  cidr_block              = local.subnets_cidrs[1]
  availability_zone       = local.availability_zones[1]

  tags = {
    Name        = "db-subnet-${var.environment}-${var.deployment}-${local.availability_zones[1]}"
    environment = var.environment
    deployment = var.deployment
  }

  depends_on = [ 
    data.aws_vpc.database
  ]
}

resource "aws_db_subnet_group" "database" {
  description = "db subnet group"
  name        = "db_subnet_group_${var.environment}_${var.deployment}"
  subnet_ids  = [
    aws_subnet.database.id,
    aws_subnet.database2.id
  ]

  tags = {
    Name = "db-subnet-group-${var.environment}-${var.deployment}"
  }

  depends_on = [ 
    data.aws_vpc.database,
    aws_subnet.database,
    aws_subnet.database2
  ]
}

resource "aws_security_group" "database" {
  name = "db-sg-${var.environment}-${var.deployment}"

  description = "db security group"
  vpc_id      = data.aws_vpc.database.id

  ingress {
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = "tcp"
    description = "db mysql"
    security_groups = [data.aws_security_group.trusted.id]
  }

  # Allow outbound traffic to private subnets.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [data.aws_security_group.trusted.id]
  }

  depends_on = [
    data.aws_vpc.database,
    aws_subnet.database,
    aws_subnet.database2,
    aws_db_subnet_group.database,
  ]
}

resource "aws_db_instance" "database" {
  allocated_storage                     = 5
  max_allocated_storage                 = 6
  db_name                               = "mydb"
  port                                  = local.database_port
  engine                                = "mysql"
  engine_version                        = "5.7"
  instance_class                        = var.instance_type
  username                              = local.init_db_username
  password                              = local.init_db_password
  identifier                            = "${var.instance_name}-${var.environment}-${var.deployment}"
  iam_database_authentication_enabled   = true
  parameter_group_name                  = "default.mysql5.7"
  skip_final_snapshot                   = true
  storage_type                          = "gp2"
  
  db_subnet_group_name                  = aws_db_subnet_group.database.id
  vpc_security_group_ids = [
    aws_security_group.database.id,
  ]

  tags = {
    Name = "db-${var.environment}-${var.deployment}",
    environment = var.environment
    deployment = var.deployment
  }

  depends_on = [
    data.aws_vpc.database,
    aws_subnet.database,
    aws_subnet.database2,
    aws_db_subnet_group.database,
    aws_security_group.database
  ]
}