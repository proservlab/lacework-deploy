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
    app_name = var.app
    app_namespace = var.app_namespace
}

resource "kubernetes_deployment" "this" {
  metadata {
    name = local.app_name
    labels = {
      app = local.app_name
    }
    namespace = local.app_namespace
  }

  spec {
    replicas = 1

    selector {
        match_labels = {
            app = local.app_name
        }
    }

    template {
      metadata {
        labels = {
            app = local.app_name
        }
      }

      spec {
        container {
            image = var.image
            name  = local.app_name
            command = var.command
            args = var.args

            port {
                container_port = var.container_port
            }
        }
      }
    }
  }

  depends_on = [
    kubernetes_namespace.this
  ]
}

resource "kubernetes_service_v1" "this" {
  metadata {
      name = local.app_name
      labels = {
          app = local.app_name
      }
      namespace = local.app_namespace
      annotations = {
        "service.beta.kubernetes.io/aws-load-balancer-security-groups" = aws_security_group.this.id
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
  depends_on = [
    kubernetes_namespace.this
  ]
}