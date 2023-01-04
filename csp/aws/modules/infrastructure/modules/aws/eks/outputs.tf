#
# Outputs
#

output "config_map_aws_auth" {
  value =   <<-EOT
              apiVersion: v1
              kind: ConfigMap
              metadata:
                name: aws-auth
                namespace: kube-system
              data:
                mapRoles: |
                  - rolearn: ${aws_iam_role.node.arn}
                    username: system:node:{{EC2PrivateDNSName}}
                    groups:
                      - system:bootstrappers
                      - system:nodes
              EOT
}

output "kubeconfig" {
  value = local.kubeconfig
}

output "kubeconfig_path" {
  value = local.kubeconfig_path
}

output "cluster" {
  value = aws_eks_cluster.cluster
}

output "cluster_node_group" {
  value = aws_eks_node_group.cluster
}


output "cluster_name" {
  value = var.cluster_name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.cluster.endpoint
}

output "cluster_ca_cert" {
  value = aws_eks_cluster.cluster.certificate_authority[0].data
}

output "cluster_vpc_id" {
  value = aws_vpc.cluster.id
}

output "cluster_vpc_subnet" {
  value = local.vpc_cidr
}
output "cluster_sg_id" {
  value = aws_security_group.cluster.id
}

output "cluster_nat_public_ip" {
  value = aws_eip.nat_gateway.public_ip
}

output "cluster_openid_connect_provider" {
  value = aws_iam_openid_connect_provider.cluster
}