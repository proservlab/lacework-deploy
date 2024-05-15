# updated to allow calico deployment
resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.cluster.id
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts_on_create = "OVERWRITE"

  configuration_values = each.value.name == "vpc-cni" ? jsonencode({ 
     env = { 
       ANNOTATE_POD_IP = "true"
     } 
   }) : null

   depends_on = [
    aws_eks_node_group.cluster
  ]
}