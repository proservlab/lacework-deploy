# maintenance
locals {
    maintenance_app_name = "maintenance"
    maintenance_app_namespace = var.maintenance_namespace
    maintenance_app_role_name = "${local.maintenance_app_name}-cluster-read-write-role"
    maintenance_app_service_account = "${local.maintenance_app_name}-service-account"
}

resource "kubernetes_service_account" "maintenance" {
    metadata {
        name = local.maintenance_app_service_account
        namespace = local.maintenance_app_namespace
    }
    # automount_service_account_token = false
}

resource "kubernetes_cluster_role" "maintenance" {
  metadata {
    name = local.maintenance_app_role_name
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
                            "create",
                            "update",
                            "patch",
                            "delete"
                        ]
  }
}

resource "kubernetes_cluster_role_binding" "maintenance" {
  metadata {
    name      = "${local.maintenance_app_name}-role-binding"
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = local.maintenance_app_role_name
  }
  subject {
    kind      = "ServiceAccount"
    name      = local.maintenance_app_service_account
    namespace = local.maintenance_app_namespace
  }
}

resource "kubernetes_service_v1" "maintenance" {
    metadata {
        name = local.maintenance_app_name
        labels = {
            app = local.maintenance_app_name
        }
        namespace = local.maintenance_app_namespace
    }
    spec {
        selector = {
            app = local.maintenance_app_name
        }
        cluster_ip = "None"
    }

    depends_on = [
      kubernetes_deployment_v1.maintenance
    ]
}

resource "kubernetes_secret" "maintenance" {
    metadata {
        name = "${local.maintenance_app_name}-aws-credentials"
        namespace = local.maintenance_app_namespace
    }
    
    type = "Opaque"
    data = {
        "credentials" = var.secret_credentials
    }
}
resource "kubernetes_deployment_v1" "maintenance" {
    metadata {
        name = local.maintenance_app_name
        labels = {
            app = local.maintenance_app_name
        }
        namespace = local.maintenance_app_namespace
    }

    spec {
        replicas = 1

        selector {
            match_labels = {
                app = local.maintenance_app_name
            }
        }

        template {
            metadata {
                labels = {
                    app = local.maintenance_app_name
                }
            }

            spec {
                service_account_name = local.maintenance_app_service_account
                # automount_service_account_token = false
                container {
                    image = "ubuntu:latest"
                    name  = "maintenance"
                    command =  [ "tail" ]
                    args =  [ "-f", "/dev/null" ]
                    volume_mount {
                        name = "${local.maintenance_app_name}-aws-credentials"
                        mount_path = "/root/.aws/credentials"
                        read_only = true
                    }
                }
                volume {
                    name = "${local.maintenance_app_name}-aws-credentials"
                    secret {
                        secret_name = "${local.maintenance_app_name}-aws-credentials"
                    }
                }
            }
            
        }
    }
}

/* 
from flask import Flask

app = Flask(__name__)

@app.route('/')
def main():
    raise

app.run("0.0.0.0",debug=True) 
*/