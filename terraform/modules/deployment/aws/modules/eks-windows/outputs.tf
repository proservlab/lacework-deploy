#
# Outputs
#

output "kubeconfig_path" {
  value = module.eks-kubeconfig.kubeconfig_path
}

output "cluster" {
  value = aws_eks_cluster.eks_windows
}

# output "cluster_node_group" {
#   value = aws_eks_node_group.node_group_linux
# }

output "cluster_name" {
  value = aws_eks_cluster.eks_windows.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.eks_windows.endpoint
}

output "cluster_ca_cert" {
  value = aws_eks_cluster.eks_windows.certificate_authority[0].data
}

output "cluster_vpc_id" {
  value = aws_eks_cluster.eks_windows.vpc_config[0].vpc_id
}

output "cluster_vpc_subnet" {
  value = local.vpc_cidr
}

output "cluster_subnet" {
  value = aws_subnet.cluster
}
output "cluster_sg_id" {
  value = aws_eks_cluster.eks_windows.vpc_config[0].cluster_security_group_id
}

output "cluster_nat_public_ip" {
  value = aws_eip.nat_gateway.public_ip
}

output "cluster_openid_connect_provider" {
  value = aws_iam_openid_connect_provider.cluster
}

output "cluster_node_role_arn" {
  value = aws_iam_role.node.arn
}