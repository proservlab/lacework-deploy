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
  value = <<-EOT
            apiVersion: v1
            clusters:
            - cluster:
                server: ${aws_eks_cluster.cluster.endpoint}
                certificate-authority-data: ${aws_eks_cluster.cluster.certificate_authority[0].data}
              name: kubernetes
            contexts:
            - context:
                cluster: kubernetes
                user: aws
              name: aws
            current-context: aws
            kind: Config
            preferences: {}
            users:
            - name: aws
              user:
                exec:
                  apiVersion: client.authentication.k8s.io/v1alpha1
                  command: aws
                  args:
                    - "eks"
                    - "get-token"
                    - "--profile"
                    - "${var.aws_profile_name}"
                    - "--cluster-name"
                    - "${var.cluster_name}"
            EOT
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