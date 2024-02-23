data "aws_caller_identity" "current" {}

locals {
    cluster_name = "${var.cluster_name}-${var.environment}-${var.deployment}"
    aws_account_id = data.aws_caller_identity.current.account_id
    read_role_name = "read-pods"
}

data "aws_iam_user" "users" {
    for_each = toset(var.iam_eks_pod_readers)
    user_name = each.key
}

resource "kubernetes_config_map_v1_data" "aws_auth_configmap" {
    metadata {
        name      = "aws-auth"
        namespace = "kube-system"
    }
    data = {
        mapRoles =  <<-YAML
                    - rolearn: arn:aws:iam::${ local.aws_account_id }:role/eks-node-${ local.cluster_name }
                      username: system:node:{{EC2PrivateDNSName}}
                      groups:
                        - system:bootstrappers
                        - system:nodes
                    YAML
        mapUsers =  <<-YAML
                    %{ for iam_user in data.aws_iam_user.users }
                    - groups:
                        - ${ local.read_role_name }
                      userarn: ${ iam_user.arn }
                      username: ${ reverse(split("/", iam_user.arn))[0] }
                    %{ endfor }
                    YAML
    }

    force = true
}

resource "kubernetes_cluster_role" "read_pods" {
  metadata {
    name = local.read_role_name
  }

  rule {
    api_groups     =    [
                            "",
                        ]
    resources      =    [
                            "pods"
                        ]
    verbs          =    [
                            "get", 
                            "list", 
                            "watch"
                        ]
  }
}

resource "kubernetes_cluster_role_binding" "read_pods" {
    for_each = data.aws_iam_user.users
    metadata {
        name      = "${local.read_role_name}-${ reverse(split("/", each.value.arn))[0] }-role-binding"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = local.read_role_name
    }
    subject {
        kind      = "User"
        name      = "${ reverse(split("/", each.value.arn))[0] }"
    }
}