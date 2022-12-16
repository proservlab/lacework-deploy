# vote
locals {
    vote_app_name = "vote"
    vote_app_namespace = var.app_namespace
    vote_app_role_name = "${local.vote_app_name}-cluster-read-role"
    vote_app_service_account = "${local.vote_app_name}-service-account"
}

resource "kubernetes_service_account" "vote" {
    metadata {
        name = local.vote_app_service_account
        namespace = local.vote_app_namespace
    }
}

resource "kubernetes_cluster_role" "vote" {
    metadata {
        name = local.vote_app_role_name
    }

    rule {
        api_groups     =    [
                                "",
                            ]
        resources      =    [
                                "*"
                            ]
        verbs          =    [
                                "get", 
                                "list", 
                                "watch",
                            ]
    }
}

resource "kubernetes_cluster_role_binding" "vote" {
  metadata {
    name      = "${local.vote_app_name}-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = local.vote_app_role_name
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.vote_app_service_account
  }
}

resource "kubernetes_service_v1" "vote" {
    metadata {
        name = local.vote_app_name
        labels = {
            app = local.vote_app_name
        }
        namespace = local.vote_app_namespace
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.app_lb.id
          "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "environment=${var.environment}"
        }
    }
    spec {
        selector = {
            app = local.vote_app_name
        }

        # session_affinity = "ClientIP"
        port {
            name = "${local.vote_app_name}-service"
            port        = 5000
            target_port = 80
        }

        type = "LoadBalancer"
    }
}
resource "kubernetes_deployment_v1" "vote" {
    metadata {
        name = local.vote_app_name
        labels = {
            app = local.vote_app_name
        }
        namespace = local.vote_app_namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = local.vote_app_name
            }
        }

        template {
            metadata {
                labels = {
                    app = local.vote_app_name
                }
            }

            spec {
                container {
                    image = "${aws_ecr_repository.repo.repository_url}:${var.tag}"
                    name  = local.vote_app_name
                }
            }
        }
    }

    depends_on = [
      kubernetes_deployment_v1.db,
      kubernetes_deployment_v1.redis
    ]
}