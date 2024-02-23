
##################################################
# LOCALS
##################################################

# manage the app deployment to this cluster in separate project - things that could be applied here are:
# - token hardening
# - default namespaces
# - default app deployment daemonsets

resource "kubernetes_namespace" "namespace" {
  metadata {
    name = var.environment
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = "terraform-example-app"
    labels = {
      app = "example-app"
    }
    namespace = var.environment
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "${var.environment}-app"
      }
    }

    template {
      metadata {
        labels = {
          app = "${var.environment}-app"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"

          # resources {
          #   limits = {
          #     cpu    = "0.5"
          #     memory = "512Mi"
          #   }
          #   requests = {
          #     cpu    = "250m"
          #     memory = "50Mi"
          #   }
          # }

          # liveness_probe {
          #   http_get {
          #     path = "/nginx_status"
          #     port = 80

          #     http_header {
          #       name  = "X-Custom-Header"
          #       value = "Awesome"
          #     }
          #   }

          #   initial_delay_seconds = 3
          #   period_seconds        = 3
          # }
        }
      }
    }
  }
}