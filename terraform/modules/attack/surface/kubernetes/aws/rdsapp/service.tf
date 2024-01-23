resource "kubernetes_service_v1" "this" {
    metadata {
        name = local.app_name
        labels = {
            app = local.app_name
        }
        namespace = local.app_namespace
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.app_lb.id
          "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "environment=${var.environment}"
        }
    }
    spec {
        selector = {
            app = local.app_name
        }

        # session_affinity = "ClientIP"
        port {
            name = "${local.app_name}-service"
            port        = var.service_port
            target_port = var.container_port
        }

        type = "LoadBalancer"
    }
}