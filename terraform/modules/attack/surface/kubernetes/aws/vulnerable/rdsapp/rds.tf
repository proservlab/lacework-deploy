resource "random_string" "root_db_password" {
    length            = 16
    special           = false
    upper             = true
    lower             = true
    numeric           = true
}

locals {
  init_db_username = var.root_db_username
  init_db_password = random_string.root_db_password

  service_account_db_user = var.service_account_db_user
  service_account = var.service_account

  database_name = var.database_name
  database_port = var.database_port

  subnets_cidrs = [
      cidrsubnet(var.cluster_vpc_subnet,8,200),
      cidrsubnet(var.cluster_vpc_subnet,8,201)
  ]

  availability_zones = [
      data.aws_availability_zones.available.names[0],
      data.aws_availability_zones.available.names[1]
  ]
}

data "aws_iam_openid_connect_provider" "cluster" {
  arn = var.cluster_openid_connect_provider_arn
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(var.cluster_openid_connect_provider_url, "https://", "")}:sub"
      values   = ["system:serviceaccount:${var.namespace}:${local.service_account}"]
    }
    principals {
      identifiers = [var.cluster_openid_connect_provider_arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "database" {
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  name               = "rdsapp-database-connect-role"
}

data "aws_iam_policy_document" "database" {
  statement {
    actions = ["rds-db:connect"]
    effect  = "Allow"
    resources = [
      "arn:aws:rds-db:${var.region}:${data.aws_caller_identity.current.account_id}:dbuser:${aws_db_instance.database.resource_id}/${local.service_account_db_user}"
    ]
  }
}

resource "aws_iam_role_policy" "database" {
 name = "rdsapp-database-connect-policy"
 role = "${aws_iam_role.database.id}"

 policy = data.aws_iam_policy_document.database.json
}

resource "kubernetes_service_account" "database" {
    metadata {
        name = "database"
        namespace = var.namespace
        annotations = {
            "eks.amazonaws.com/role-arn" = aws_iam_role.database.arn
        }
    }
}

resource "aws_subnet" "database" {
  vpc_id                  = var.cluster_vpc_id
  count                   = length(local.subnets_cidrs)
  cidr_block              = element(local.subnets_cidrs, count.index)
  availability_zone       = element(local.availability_zones, count.index)

  tags = {
    Name        = "${var.environment}-${element(local.availability_zones, count.index)}-private-subnet"
    environment = var.environment
    deployment = var.deployment
  }
}

resource "aws_db_subnet_group" "database" {
  description = "rdsapp db subnet group"
  name        = "rdsapp_subnet_group"
  subnet_ids  = aws_subnet.database.*.id

  tags = {
    Name = var.environment
  }
}

resource "aws_security_group" "database" {
  name = "${var.environment}-rdsapp-mysql-private-sg"

  description = "rdsapp security group"
  vpc_id      = var.cluster_vpc_id

  ingress {
    from_port   = local.database_port
    to_port     = local.database_port
    protocol    = "tcp"
    description = "rdsapp mysql"
    security_groups = [var.cluster_sg_id]
  }

  # Allow outbound traffic to private subnets.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [var.cluster_sg_id]
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
  identifier                            = "rdsapp-${var.environment}-${var.deployment}"
  iam_database_authentication_enabled   = true
  parameter_group_name                  = "default.mysql5.7"
  skip_final_snapshot                   = true
  
  db_subnet_group_name                  = aws_db_subnet_group.database.id
  vpc_security_group_ids = [
    aws_security_group.database.id,
  ]

  tags = {
    Name = "rdsapp-${var.environment}",
    environment = var.environment
    deployment = var.deployment
  }
}

locals {
  
  database = templatefile(
                          "${path.module}/resources/bootstrap.sql.tpl",
                          {
                            iam_db_user = local.service_account_db_user
                            database_name = local.database_name
                          }
                        )
  rds_cert = templatefile(
                          "${path.module}/resources/rds-combined-ca-bundle.pem",
                          {}
                        )
}

# bootstrap iam user
resource "kubernetes_job_v1" "database_bootstrap" {
  metadata {
    name = "dbbootstrap"
    namespace = var.namespace
  }
  spec {
    template {
      metadata {}
      spec {
        container {
          name    = "mysql-client"
          image   = "mysql:8.0.31"
          command = ["/bin/sh", "-c"]
          args =    [
                    <<EOT
                    echo ${base64encode(local.rds_cert)} | base64 -d > rds-combined-ca-bundle.pem && \
                    /bin/sh <<< $(echo ${base64encode("mysql --ssl-ca=rds-combined-ca-bundle.pem --ssl-mode=REQUIRED -h $DB_APP_URL -u${local.init_db_username} -p${local.init_db_password} <<< $(echo ${base64encode(local.database)} | base64 -d)")} | base64 -d)
                    EOT
          ]
          env {
                name = "DB_APP_URL"
                value = split(":", aws_db_instance.database.endpoint)[0]
            }
        }
        restart_policy = "Never"
      }
    }
    backoff_limit = 4
    ttl_seconds_after_finished = 120
  }
  wait_for_completion = true
}