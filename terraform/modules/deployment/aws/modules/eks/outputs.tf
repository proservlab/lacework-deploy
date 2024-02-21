#
# Outputs
#

output "kubeconfig_path" {
  value = module.eks-kubeconfig.kubeconfig_path
}

output "cluster" {
  value = aws_eks_cluster.cluster
}

output "cluster_node_group" {
  value = aws_eks_node_group.cluster
}

output "cluster_name" {
  value = aws_eks_cluster.cluster.id
}

output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "cluster_ca_cert" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "cluster_vpc_id" {
  value = aws_eks_cluster.cluster.vpc_config[0].vpc_id
}

output "cluster_vpc_subnet" {
  value = local.vpc_cidr
}
output "cluster_sg_id" {
  value = aws_eks_cluster.cluster.vpc_config[0].cluster_security_group_id
}

output "cluster_nat_public_ip" {
  value = aws_eip.nat_gateway.public_ip
}

output "cluster_openid_connect_provider" {
  value = aws_iam_openid_connect_provider.cluster
}