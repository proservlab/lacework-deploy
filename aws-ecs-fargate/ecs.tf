locals {
  lacework_image = "lacework/datacollector:latest-sidecar"
  lacework_entrypoint = "/var/lib/lacework-backup/lacework-sidecar.sh"
  
  entrypoint = "/var/lib/lacework-backup/lacework-sidecar.sh"
  command = "/app/entrypoint.sh"
  # scratch example
  # lacework_image = "${aws_ecr_repository.lacework-repo.repository_url}:${var.lacework_tag}"
  # lacework_entrypoint = "/var/lib/lacework-backup/lacework-sidecar-minimal.sh"
}
resource "aws_ecs_cluster" "app" {
  name = "${var.environment}-ecs-1"
}

resource "aws_ecs_cluster_capacity_providers" "cluster" {
  cluster_name = aws_ecs_cluster.app.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

resource "aws_appautoscaling_target" "app_scale_target" {
  service_namespace  = "ecs"
  resource_id        = "service/${aws_ecs_cluster.app.name}/${aws_ecs_service.web-image.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  max_capacity       = 1
  min_capacity       = 1
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.app}-${var.environment}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  # defined in role.tf
  task_role_arn = aws_iam_role.app_role.arn
  container_definitions = jsonencode(
[
  {
    "name": "datacollector-sidecar",
    "image": "${local.lacework_image}",
    "cpu": 0,
    "portMappings": [],
    "essential": false,
    "environment": [],
    "volumesFrom": [],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.lacework.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  },
  {
    "essential": true,
    "image": "${aws_ecr_repository.repo.repository_url}:${var.tag}",
    "memory": 512,
    "name": "web-image",
    "cpu": 256,
    "portMappings": [
      {
        "containerPort": 5000,
        "hostPort": 5000,
        "protocol": "tcp"
      }
    ],
    "environment": [
      {
        "name": "PORT",
        "value": "5000"
      },
      {
        "name": "PRODUCT",
        "value": "${var.app}"
      },
      {
        "name": "ENVIRONMENT",
        "value": "${var.environment}"
      },
      {
        "name": "LaceworkAccessToken",
        "value": "${lacework_agent_access_token.main.token}"
      },
      {
        "name": "LaceworkVerbose",
        "value": "true"
      }
    ],
    "entryPoint": [
      "${local.entrypoint}"
    ],
    "command": [
      "${local.command}"
    ],
    "volumesFrom": [
      {
        "sourceContainer": "datacollector-sidecar",
        "readOnly": true
      }
    ],
    "dependsOn": [
      {
        "containerName": "datacollector-sidecar",
        "condition": "SUCCESS"
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${aws_cloudwatch_log_group.logs.name}",
        "awslogs-region": "${var.region}",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]
)

  

  depends_on = [
      null_resource.push
  ]
}

resource "aws_ecs_service" "web-image" {
  name            = "web-image"
  cluster         = aws_ecs_cluster.app.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 1

  network_configuration {
    security_groups = [aws_security_group.alb_security_group.id]
    subnets            = [
      aws_subnet.main-subnet-public-1.id,
      aws_subnet.main-subnet-public-2.id
    ]
    assign_public_ip = true
  }

  # load_balancer {
  #   target_group_arn = aws_lb_target_group.main.arn
  #   container_name   = "web-image"
  #   container_port   = 5000
  # }

  # depends_on = [aws_lb_listener.ecs]

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  lifecycle {
    ignore_changes = [task_definition]
  }
}

variable "logs_retention_in_days" {
  type        = number
  default     = 90
  description = "Specifies the number of days you want to retain log events"
}

resource "aws_cloudwatch_log_group" "logs" {
  name              = "/fargate/service/${var.app}-${var.environment}"
  retention_in_days = var.logs_retention_in_days
  tags              = {
      Name = "main-log-group-${var.app}-${var.environment}"
  }
}

resource "aws_cloudwatch_log_group" "lacework" {
  name = "/fargate/lacework/lacework-datacollector-sidecar"
  retention_in_days = var.logs_retention_in_days
  tags              = {
      Name = "main-log-group-lacework-${var.environment}"
  }
}
