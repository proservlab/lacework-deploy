resource "kubernetes_namespace" "rds_connect" {
    metadata {
        name = var.namespace
    }
}