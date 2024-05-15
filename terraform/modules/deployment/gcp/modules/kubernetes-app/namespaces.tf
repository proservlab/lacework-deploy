resource "kubernetes_namespace" "this" {
    metadata {
        name = var.app_namespace
    }
}