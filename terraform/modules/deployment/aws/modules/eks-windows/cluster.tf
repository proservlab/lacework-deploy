#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "cluster" {
  name = "eks-cluster-${var.environment}-${var.deployment}"

  assume_role_policy = <<-EOT
                          {
                            "Version": "2012-10-17",
                            "Statement": [
                              {
                                "Effect": "Allow",
                                "Principal": {
                                  "Service": "eks.amazonaws.com"
                                },
                                "Action": "sts:AssumeRole"
                              }
                            ]
                          }
                          EOT
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

resource "aws_iam_role_policy_attachment" "cluster-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster.name
}

resource "aws_security_group" "cluster" {
  name        = "eks-cluster-${var.environment}-${var.deployment}"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.cluster.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.cluster_name}-${var.environment}-${var.deployment}"
    Env = var.environment
  }
}

resource "aws_security_group_rule" "cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_cloudwatch_log_group" "example" {
  name              = "/aws/eks/${var.cluster_name}/${var.environment}/${var.deployment}/cluster"
  retention_in_days = 3
}


## EKS Cluster
resource "aws_eks_cluster" "eks_windows" {
  name     = "${var.cluster_name}-${var.environment}-${var.deployment}"
  role_arn = aws_iam_role.cluster.arn
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  version = var.cluster_version

  vpc_config {
    security_group_ids = [aws_security_group.cluster.id]
    subnet_ids         = [ for subnet in aws_subnet.cluster: subnet.id ]
    public_access_cidrs  = var.public_access_cidr
    endpoint_private_access = true
    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster-AmazonEKSVPCResourceController,
    aws_cloudwatch_log_group.example
  ]
}


