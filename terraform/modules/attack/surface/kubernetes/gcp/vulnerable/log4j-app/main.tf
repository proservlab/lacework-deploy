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
            command = var.command
            args = var.args

            port {
                container_port = 8080
            }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "log4shell" {
    metadata {
        name = local.log4shell_app_name
        labels = {
            app = local.log4shell_app_name
        }
        namespace = local.log4shell_app_namespace
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

        load_balancer_source_ranges = flatten([
          var.trusted_attacker_source,
          var.trusted_workstation_source,
          var.additional_trusted_sources,
        ])
    }

    
}

