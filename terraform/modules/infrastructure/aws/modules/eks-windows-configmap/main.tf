locals {
  cluster_name = "${var.cluster_name}-${var.environment}-${var.deployment}"
}

data "aws_caller_identity" "current" {}

data "aws_ami" "eks_optimized_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Core-EKS_Optimized-${var.cluster_version}-*"]
  }
}

## Enable VPC CNI Windows Support

resource "kubernetes_config_map" "amazon_vpc_cni_windows" {
  metadata {
    name      = "amazon-vpc-cni"
    namespace = "kube-system"
  }

  data = {
    enable-windows-ipam : "true"
  }
}

## AWS CONFIGMAP

resource "kubernetes_config_map_v1_data" "configmap" {
  data = {
    "mapRoles" = <<EOT
- groups:
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-node-${ local.cluster_name }
  username: system:node:{{EC2PrivateDNSName}}
- groups:
  - eks:kube-proxy-windows
  - system:bootstrappers
  - system:nodes
  rolearn: arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/eks-node-${ local.cluster_name }
  username: system:node:{{EC2PrivateDNSName}}
EOT
  }

  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  force = true
}

## EKS Windows Node Group

resource "aws_eks_node_group" "node_group_windows" {
  cluster_name    = local.cluster_name
  node_group_name = "${var.cluster_name}-windows-nodegroup-${var.environment}-${var.deployment}"
  node_role_arn   = var.cluster_node_role_arn
  subnet_ids      = [ for subnet in var.cluster_subnet: subnet.id ]

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
}

## Windows Launch template

resource "aws_launch_template" "eks_windows_nodegroup_lt" {
  name                   = "${var.cluster_name}-${var.environment}-${var.deployment}-eks-windows-nodegroup-lt"
  vpc_security_group_ids = [var.cluster_sg]
  image_id               = data.aws_ami.eks_optimized_ami.id
  instance_type          = "t3.small"

  user_data = "${base64encode(<<EOF
<powershell>
[string]$EKSBinDir = "$env:ProgramFiles\Amazon\EKS"
[string]$EKSBootstrapScriptFile = "$env:ProgramFiles\Amazon\EKS\Start-EKSBootstrap.ps1"
& $EKSBootstrapScriptFile -EKSClusterName "${local.cluster_name}" -APIServerEndpoint "${var.cluster_endpoint}" -Base64ClusterCA "${var.cluster_ca_cert}" -DNSClusterIP "10.0.0.10" 3>&1 4>&1 5>&1 6>&1
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
    tags          = { 
      "kubernetes.io/cluster/${local.cluster_name}" = "owned", 
      "kubernetes.io/os" = "windows", 
      "kubernetes.io/arch" = "amd64", 
      "name" = "eks-windows-node" 
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
  }
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
  vpc_zone_identifier = [ for subnet in var.cluster_subnet: subnet.id ]
  health_check_type   = "EC2"

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [desired_capacity, target_group_arns]
  }
}