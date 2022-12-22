data "aws_availability_zones" "available" {}

data "aws_caller_identity" "current" {}

locals {
    kubeconfig_path = pathexpand("~/.kube/${var.environment}-kubeconfig")
    kubeconfig = <<-EOT
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
                  apiVersion: client.authentication.k8s.io/v1beta1
                  args:
                    - "--region"
                    - "${var.region}"
                    - "eks"
                    - "get-token"
                    - "--cluster-name"
                    - "${var.cluster_name}"
                  command: aws
                  env:
                  - name: AWS_PROFILE
                    value: ${var.aws_profile_name}
            EOT
}

resource "local_file" "kubeconfig" {
    depends_on = [
        aws_eks_cluster.cluster
    ]
    content  = local.kubeconfig
    filename = local.kubeconfig_path
}