resource "kubernetes_service_v1" "this" {
    metadata {
        name = local.app_name
        labels = {
            app = local.app_name
        }
        namespace = local.app_namespace
    }
    spec {
        selector = {
            app = local.app_name
        }

        # session_affinity = "ClientIP"
        port {
            name = "${local.app_name}-service"
            port        = var.service_port
            target_port = 8080
        }

        type = "LoadBalancer"

        load_balancer_source_ranges = sort(flatten([
          var.trusted_attacker_source,
          var.trusted_workstation_source,
          var.additional_trusted_sources,
        ]))
    }
}