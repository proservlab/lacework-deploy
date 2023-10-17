locals {
    cluster_name = "${var.cluster_name}-${var.environment}-${var.deployment}"
    cluster_resource_group = "${var.cluster_name}-${var.environment}-${var.deployment}-rg"
}

resource "random_id" "uniq" {
  byte_length = 4
}

resource "azurerm_resource_group" "this" {
  name     = local.cluster_resource_group
  location = var.region

  tags = {
    environment = var.environment
    deployment = var.deployment
  }
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = local.cluster_name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "${random_id.uniq.hex}"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  api_server_access_profile {
    authorized_ip_ranges = var.authorized_ip_ranges
  }

  identity {
    type = "SystemAssigned"
  }
}

module "azure-aks-kubeconfig" {
  source = "../aks-kubeconfig"
  environment = var.environment
  deployment = var.deployment
  cluster_name = azurerm_kubernetes_cluster.this.name
  cluster_resource_group = azurerm_resource_group.this.name

  depends_on = [
    azurerm_kubernetes_cluster.this
  ]
}