resource "kubernetes_service_v1" "vote" {
    metadata {
        name = var.app
        labels = {
            app = var.app
        }
        namespace = var.namespace
        annotations = {
          "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.app_lb.id
          "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "environment=${var.environment}"
        }
    }
    spec {
        selector = {
            app = var.app
        }

        # session_affinity = "ClientIP"
        port {
            name = "${var.app}-service"
            port        = var.service_port
            target_port = 80
        }

        type = "LoadBalancer"
    }
}