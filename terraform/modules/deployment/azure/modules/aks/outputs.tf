output "kubeconfig_path" {
  value = module.azure-aks-kubeconfig.kubeconfig_path
}

output "cluster" {
  value = azurerm_kubernetes_cluster.this
}

output "cluster_name" {
  value = azurerm_kubernetes_cluster.this.name
}

output "cluster_endpoint" {
  value = azurerm_kubernetes_cluster.this.kube_admin_config[0].cluster_ca_certificate 
}

output "cluster_ca_certificate" {
  value = azurerm_kubernetes_cluster.this.kube_admin_config[0].cluster_ca_certificate 
}

output "cluster_resource_group" {
  value = azurerm_resource_group.this.name
}


