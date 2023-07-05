#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

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
  cluster_name    = aws_eks_cluster.cluster.name
  node_group_name = var.cluster_name
  node_role_arn   = aws_iam_role.node.arn
  subnet_ids      = [ for subnet in aws_subnet.cluster: subnet.id ]
  instance_types = [ "t3.small" ]

  scaling_config {
    desired_size = var.enable_calico == true ? 4 : 3
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