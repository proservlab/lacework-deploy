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
            env {
                name = "DB_APP_URL"
                value = split(":", aws_db_instance.database.endpoint)[0]
            }
            env {
                name = "DB_USER_NAME"
                value = var.service_account_db_user
            }
            env {
                name = "DB_NAME"
                value = var.database_name
            }
            env {
                name = "DB_PORT"
                value = var.database_port
            }
            env {
                name = "DB_REGION"
                value = var.region
            }
        }
        
      }
    }
  }

  depends_on = [
    kubernetes_job_v1.database_bootstrap
  ]
}