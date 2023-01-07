data "aws_availability_zones" "available" {}

locals {
  init_db_username = var.root_db_username
  init_db_password = var.root_db_password
  
  database_port = var.database_port

  subnets_cidrs = [
      cidrsubnet(var.vpc_subnet,8,200),
      cidrsubnet(var.vpc_subnet,8,201)
  ]

  availability_zones = [
      data.aws_availability_zones.available.names[0],
      data.aws_availability_zones.available.names[1]
  ]
}

resource "aws_route_table" "database" {
    vpc_id = var.vpc_id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = var.igw_id
    }

    tags = {
        Name = "${var.environment}-ec2db-internet-gw-route"
    }
}

resource "aws_route_table_association" "database" {
  count = length(local.subnets_cidrs)
  subnet_id = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database[count.index].id
}

resource "aws_subnet" "database" {
  vpc_id                  = var.vpc_id
  count                   = length(local.subnets_cidrs)
  cidr_block              = element(local.subnets_cidrs, count.index)
  availability_zone       = element(local.availability_zones, count.index)

  tags = {
    Name        = "${var.environment}-${element(local.availability_zones, count.index)}-db-subnet"
    Environment = var.environment
  }
}

resource "aws_db_subnet_group" "database" {
  description = "db subnet group"
  name        = "db_subnet_group"
  subnet_ids  = aws_subnet.database.*.id

  tags = {
    Name = var.environment
  }
}

resource "aws_security_group" "database" {
  name = "${var.environment}-db-sg"

  description = "db security group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = var.database_port
    to_port     = var.database_port
    protocol    = "tcp"
    description = "db mysql"
    security_groups = [var.trusted_sg_id]
  }

  # Allow outbound traffic to private subnets.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [var.trusted_sg_id]
  }
}

resource "aws_db_instance" "database" {
  allocated_storage                     = 5
  max_allocated_storage                 = 10
  db_name                               = "mydb"
  port                                  = local.database_port
  engine                                = "mysql"
  engine_version                        = "5.7"
  instance_class                        = "db.t3.micro"
  username                              = local.init_db_username
  password                              = local.init_db_password
  identifier_prefix                     = "ec2rds-${var.environment}"
  iam_database_authentication_enabled   = true
  parameter_group_name                  = "default.mysql5.7"
  skip_final_snapshot                   = true
  
  db_subnet_group_name                  = aws_db_subnet_group.database.id
  vpc_security_group_ids = [
    aws_security_group.database.id,
  ]

  tags = {
    Name = "${var.environment}-db",
    Environment = var.environment
  }
}