data "aws_caller_identity" "current" {}

locals {
    cluster_name = "${var.cluster_name}-${var.environment}-${var.deployment}"
    aws_account_id = data.aws_caller_identity.current.account_id
    use_assumed_role = can(regex(".*:assumed-role/(.*)/", data.aws_caller_identity.current.arn))
    current_user_arn       = local.use_assumed_role ? "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${regex(".*:assumed-role/(.*)/", data.aws_caller_identity.current.arn)[0]}" : data.aws_caller_identity.current.arn
    read_role_name = "read-pods"
    admin_role_name = "admin-pods"


    current_user_admins = local.use_assumed_role ? [] : [ local.current_user_arn ]
    current_role_admins = local.use_assumed_role ? [ local.current_user_arn ] : []

    iam_eks_admins = var.iam_eks_admins
    iam_eks_readers = var.iam_eks_readers
}

data "aws_iam_user" "read_users" {
    for_each = toset(var.iam_eks_readers)
    user_name = each.key
}

data "aws_iam_user" "admin_users" {
    for_each = toset(var.iam_eks_admins)
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
                    %{ for user_arn in local.current_role_admins }
                    - groups:
                        - ${ local.admin_role_name }
                      rolearn: ${ user_arn }
                      username: ${ regex(".*:assumed-role/(.*)/", data.aws_caller_identity.current.arn)[0] }
                    %{ endfor }
                    %{ for user_arn in local.current_user_admins }
                    - groups:
                        - ${ local.admin_role_name }
                      userarn: ${ user_arn }
                      username: ${ reverse(split("/", user_arn))[0] }
                    %{ endfor }
                    %{ for iam_user in data.aws_iam_user.read_users }
                    - groups:
                        - ${ local.read_role_name }
                      userarn: ${ iam_user.arn }
                      username: ${ reverse(split("/", iam_user.arn))[0] }
                    %{ endfor }
                    %{ for iam_user in data.aws_iam_user.admin_users }
                    - groups:
                        - ${ local.admin_role_name }
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
                            "*",
                        ]
    resources      =    [
                            "*"
                        ]
    verbs          =    [
                            "get", "list", "patch", "update", "watch"
                        ]
  }
}

resource "kubernetes_cluster_role_binding" "read_pods" {
    for_each = data.aws_iam_user.read_users
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

resource "kubernetes_cluster_role" "admin" {
  metadata {
    name = local.admin_role_name
  }

  rule {
    api_groups     =    [
                            "*"
                        ]
    resources      =    [
                            "*"
                        ]
    verbs          =    [
                            "*"
                        ]
  }
}

resource "kubernetes_cluster_role_binding" "admin_pods" {
    for_each = data.aws_iam_user.admin_users
    metadata {
        name      = "${local.admin_role_name}-${ reverse(split("/", each.value.arn))[0] }-role-binding"
    }
    role_ref {
        api_group = "rbac.authorization.k8s.io"
        kind      = "ClusterRole"
        name      = local.admin_role_name
    }
    subject {
        kind      = "User"
        name      = "${ reverse(split("/", each.value.arn))[0] }"
    }
}