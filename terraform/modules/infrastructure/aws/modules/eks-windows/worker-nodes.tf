#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

data "aws_eks_cluster" "eks_windows" {
  name = aws_eks_cluster.eks_windows.name
}

data "aws_ami" "eks_optimized_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Core-EKS_Optimized-${var.cluster_version}-*"]
  }
}

resource "aws_iam_role" "node" {
  name = "eks-node-${var.cluster_name}-${var.environment}-${var.deployment}"

  assume_role_policy = <<-EOT
                          {
                            "Version": "2012-10-17",
                            "Statement": [
                              {
                                "Effect": "Allow",
                                "Principal": {
                                  "Service": "ec2.amazonaws.com"
                                },
                                "Action": "sts:AssumeRole"
                              }
                            ]
                          }
                          EOT
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node.name
}
resource "aws_iam_role_policy_attachment" "node-AmazonEBSCSIDriverPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node-AmazonSSMPatchAssociation" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMPatchAssociation"
  role       = aws_iam_role.node.name
}



resource "aws_eks_node_group" "cluster" {
  cluster_name    = aws_eks_cluster.eks_windows.name
  node_group_name = var.cluster_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [ for subnet in aws_subnet.cluster: subnet.id ]
  instance_types = [ "t3.small" ]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }

  tags =  {
            "k8s.io/cluster-autoscaler/enabled" = "true"
            "k8s.io/cluster-autoscaler/${var.cluster_name}-${var.environment}-${var.deployment}" = "owned"
            "Name" = "terraform-eks-worker-node"
          }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEBSCSIDriverPolicy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node-AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.node-AmazonSSMPatchAssociation,
  ]
}

## EKS Linux Node Group

resource "aws_eks_node_group" "node_group_linux" {
  cluster_name    = aws_eks_cluster.eks_windows.name
  node_group_name = "${var.cluster_name}-linux-nodegroup-${var.environment}-${var.deployment}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [ for subnet in aws_subnet.cluster: subnet.id ]

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 2
  }

  update_config {
    max_unavailable = 2
  }

   tags =  {
            "k8s.io/cluster-autoscaler/enabled" = "true"
            "k8s.io/cluster-autoscaler/${var.cluster_name}-${var.environment}-${var.deployment}" = "owned"
            "Name" = "terraform-eks-linux-node"
          }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEBSCSIDriverPolicy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node-AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.node-AmazonSSMPatchAssociation,
  ]
}

## EKS Windows Node Group

resource "aws_eks_node_group" "node_group_windows" {
  cluster_name    = aws_eks_cluster.eks_windows.name
  node_group_name = "${var.cluster_name}-windows-nodegroup-${var.environment}-${var.deployment}"
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [ for subnet in aws_subnet.cluster: subnet.id ]

  launch_template {
    name = aws_launch_template.eks_windows_nodegroup_lt.name
    version = aws_launch_template.eks_windows_nodegroup_lt.latest_version
  }

  scaling_config {
    desired_size = 1
    max_size     = 5
    min_size     = 1
  }

  update_config {
    max_unavailable = 2
  }

  tags =  {
            # "k8s.io/cluster-autoscaler/enabled" = "true"
            # "k8s.io/cluster-autoscaler/${var.cluster_name}-${var.environment}-${var.deployment}" = "owned"
            "Name" = "eks-windows-worker-node"
          }

  depends_on = [
    aws_iam_role_policy_attachment.node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node-AmazonEBSCSIDriverPolicy,
    aws_iam_role_policy_attachment.node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.node-AmazonSSMManagedInstanceCore,
    aws_iam_role_policy_attachment.node-AmazonSSMPatchAssociation,
  ]
}

## Windows Launch template

resource "aws_launch_template" "eks_windows_nodegroup_lt" {
  name                   = "${var.cluster_name}-${var.environment}-${var.deployment}-eks-windows-nodegroup-lt"
  vpc_security_group_ids = [aws_security_group.cluster.id]
  image_id               = data.aws_ami.eks_optimized_ami.id
  instance_type          = "t3.large"

  user_data = "${base64encode(<<EOF
<powershell>
[string]$EKSBinDir = "$env:ProgramFiles\Amazon\EKS"
[string]$EKSBootstrapScriptFile = "$env:ProgramFiles\Amazon\EKS\Start-EKSBootstrap.ps1"
& $EKSBootstrapScriptFile -EKSClusterName "${aws_eks_cluster.eks_windows.name}" -APIServerEndpoint "${aws_eks_cluster.eks_windows.endpoint}" -Base64ClusterCA "${aws_eks_cluster.eks_windows.certificate_authority[0].data}" -DNSClusterIP "10.0.0.10" 3>&1 4>&1 5>&1 6>&1
</powershell>
EOF
  )}"

  monitoring {
    enabled = false
  }

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size           = "50"
      delete_on_termination = true
      volume_type           = "gp3"
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags          = { "kubernetes.io/cluster/${aws_eks_cluster.eks_windows.name}" = "owned", "kubernetes.io/os" = "windows", "name" = "eks-windows-node" }
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
  depends_on = [
    aws_eks_cluster.eks_windows
  ]
}

## Auto Scaling group

resource "aws_autoscaling_group" "eks-windows-nodegroup-asg" {

  name             = "Windows_worker_nodes_asg"
  desired_capacity = 1
  max_size         = 5
  min_size         = 1
  #target_group_arns = [var.external_alb_target_group_arn]
  launch_template {
    id      = aws_launch_template.eks_windows_nodegroup_lt.id
    version = "$Latest"
  }
  vpc_zone_identifier = [ for subnet in aws_subnet.cluster: subnet.id ]
  health_check_type   = "EC2"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity, target_group_arns]
  }
}