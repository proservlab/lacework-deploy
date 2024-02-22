data "kubernetes_all_namespaces" "allns" {}

resource "kubernetes_namespace" "this" {
  for_each = toset([ for k in [var.app_namespace] : k if !contains(keys(data.kubernetes_all_namespaces.allns), k) && k != "default" ])
  metadata {
    name = each.key
  }
  depends_on = [data.kubernetes_all_namespaces.allns] # potentially more if you want to refresh list of NS
}