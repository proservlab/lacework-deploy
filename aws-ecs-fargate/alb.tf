resource "aws_lb" "ecs" {
  name               = "basic-load-balancer"
  load_balancer_type = "network"
  subnets            = [
      aws_subnet.main-subnet-public-1.id,
      aws_subnet.main-subnet-public-2.id

  ]

  enable_cross_zone_load_balancing = true
}

data "aws_network_interfaces" "ecs" {
  filter {
    name = "description"
    values = ["ELB net/${aws_lb.ecs.name}/*"]
  }
  filter {
    name = "vpc-id"
    values = ["${aws_vpc.main.id}"]
  }
  filter {
    name = "status"
    values = ["in-use"]
  }
  filter {
    name = "attachment.status"
    values = ["attached"]
  }
}

# locals {
#   alb_interface_ids = "${flatten(["${data.aws_network_interfaces.ecs.ids}"])}"
# }

# data "aws_network_interface" "ifs" {
#   count = "${length(local.alb_interface_ids)}"
#   id = "${local.alb_interface_ids[count.index]}"
# }

# output "aws_lb_network_interface_ips" {
#   value = "${flatten([data.aws_network_interface.ifs.*.private_ips])}"
# }

output "aws_lb_network_interface_ips" {
  value = "${flatten([data.aws_network_interfaces.ecs.id])}"
}

resource "aws_lb_listener" "ecs" {
  load_balancer_arn = aws_lb.ecs.arn
  port                = 5000
  protocol            = "TCP"
#   port              = 443
#   protocol          = "HTTPS"

#   ssl_policy        = "ELBSecurityPolicy-2016-08"
#   certificate_arn   = aws_acm_certificate.this.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

# data "aws_acm_certificate" "this" {
#   domain = "${var.dns_record_name}.${var.dns_zone_name}"
# }



resource "aws_lb_target_group" "main" {
  vpc_id      = aws_vpc.main.id
  protocol    = "TCP"
  port        = 5000
  target_type = "ip"

#   health_check {
#     enabled             = true
#     interval            = 10
#     path                = "/"
#     port                = 5000
#     protocol            = "HTTP"
#     timeout             = 5
#     healthy_threshold   = 2
#     unhealthy_threshold = 10
#     matcher             = null
#   }

  # NOTE: TF is unable to destroy a target group while a listener is attached,
  # therefor we have to create a new one before destroying the old. This also means
  # we have to let it have a random name, and then tag it with the desired name.
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_lb_target_group" "default" {
  arn = aws_lb_target_group.main.arn
}