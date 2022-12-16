# vote
locals {
    name = "vote"
    namespace = var.app_namespace
    role_name = "${local.name}-cluster-read-role"
    service_account = "${local.name}-service-account"
}

resource "kubernetes_service_account" "vote" {
    metadata {
        name = local.service_account
        namespace = local.namespace
    }
}

resource "kubernetes_cluster_role" "vote" {
    metadata {
        name = local.role_name
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
    name      = "${local.name}-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = local.role_name
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.service_account
  }
}

resource "kubernetes_service_v1" "vote" {
    metadata {
        name = local.name
        labels = {
            app = local.name
        }
        namespace = local.namespace
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.app_lb.id
          "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "environment=${var.environment}"
        }
    }
    spec {
        selector = {
            app = local.name
        }

        # session_affinity = "ClientIP"
        port {
            name = "${local.name}-service"
            port        = 5000
            target_port = 80
        }

        type = "LoadBalancer"
    }
}
resource "kubernetes_deployment_v1" "vote" {
    metadata {
        name = local.name
        labels = {
            app = local.name
        }
        namespace = local.namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = local.name
            }
        }

        template {
            metadata {
                labels = {
                    app = local.name
                }
            }

            spec {
                container {
                    image = "${aws_ecr_repository.repo.repository_url}:${var.tag}"
                    name  = local.name
                }
            }
        }
    }

    depends_on = [
      kubernetes_deployment_v1.db,
      kubernetes_deployment_v1.redis
    ]
}