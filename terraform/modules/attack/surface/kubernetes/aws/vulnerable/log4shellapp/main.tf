##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../../../../context/deployment"
}

##################################################
# LOCALS
##################################################

locals {
    log4shell_app_name = var.app
    log4shell_app_namespace = var.app_namespace
}

resource "kubernetes_deployment" "vulnerable_log4shell_pod" {
  metadata {
    name = local.log4shell_app_name
    labels = {
      app = local.log4shell_app_name
    }
    namespace = local.log4shell_app_namespace
  }

  spec {
    replicas = 1

    selector {
        match_labels = {
            app = local.log4shell_app_name
        }
    }

    template {
      metadata {
        labels = {
            app = local.log4shell_app_name
        }
      }

      spec {
        container {
            image = var.image
            name  = local.log4shell_app_name
            command = ["java"]
            args = ["-jar", "/app/spring-boot-application.jar"]

            port {
                container_port = 8080
            }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.app
  ]
}

resource "kubernetes_service_v1" "log4shell" {
  metadata {
      name = local.log4shell_app_name
      labels = {
          app = local.log4shell_app_name
      }
      namespace = local.log4shell_app_namespace
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.app_lb.id
        "service.beta.kubernetes.io/aws-load-balancer-additional-resource-tags" = "environment=${var.environment}"
      }
  }
  spec {
      selector = {
          app = local.log4shell_app_name
      }

      # session_affinity = "ClientIP"
      port {
          name = "${local.log4shell_app_name}-service"
          port        = var.service_port
          target_port = 8080
      }

      type = "LoadBalancer"
  }
  depends_on = [
    kubernetes_namespace.app
  ]
}