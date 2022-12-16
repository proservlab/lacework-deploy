# app lb security group
resource "aws_security_group" "app_lb" {
  name        = "app_lb"
  description = "Allow inbound traffic from trusted source"
  vpc_id      = var.cluster_vpc_id

  ingress {
    description      = "Allow 1024-65535"
    from_port        = 1024
    to_port          = 65536
    protocol         = "tcp"
    cidr_blocks      =  var.lb_trusted_source
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.app}-allow-lb-inbound"
  }
}