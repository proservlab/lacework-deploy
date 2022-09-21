# resource "random_pet" "prefix" {}

# resource "azurerm_resource_group" "default" {
#   name     = "${var.cluster_name}-rg"
#   location = var.region

#   tags = {
#     environment = var.environment
#   }
# }

# resource "azurerm_kubernetes_cluster" "default" {
#   name                = var.cluster_name
#   location            = azurerm_resource_group.default.location
#   resource_group_name = azurerm_resource_group.default.name
#   dns_prefix          = "${random_pet.prefix.id}-k8s"

#   default_node_pool {
#     name            = "default"
#     node_count      = 2
#     vm_size         = "Standard_D2_v2"
#     os_disk_size_gb = 30
#   }

#   service_principal {
#     client_id     = var.appId
#     client_secret = var.password
#   }

#   role_based_access_control {
#     enabled = true
#   }

#   tags = {
#     environment = var.environment
#   }
# }


# ensure that we update the local config after the build of our cluster (yes there are better ways to do this)
# resource "null_resource" "eks_context_switcher" {

#   triggers = {
#     always_run = timestamp()
#   }

#   provisioner "local-exec" {
#     command = "az aks get-credentials -n ${var.cluster_name} -g ${var.cluster_name}-rg"
#   }

#   depends_on = [
#     aws_eks_cluster.cluster
#   ]
# }