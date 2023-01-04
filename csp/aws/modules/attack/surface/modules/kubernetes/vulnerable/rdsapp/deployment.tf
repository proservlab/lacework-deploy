resource "kubernetes_deployment" "vulnerable_privileged_pod" {
  metadata {
    name = "vulnerable-rdsapp"
    labels = {
      app = "vulnerable-rdsapp"
    }
    namespace = var.namespace
  }

  spec {
    replicas = 1

    selector {
        match_labels = {
            app = "vulnerable-rdsapp"
        }
    }

    template {
      metadata {
        labels = {
            app = "vulnerable-rdsapp"
        }
      }

      spec {
        service_account_name = "database"
        container {
            image = "ubuntu:latest"
            name  = "maintenance"
            command = ["tail"]
            args = ["-f", "/dev/null"] 
        }
      }
    }
  }

  depends_on = [
    kubernetes_job_v1.database_bootstrap
  ]
}