variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))

  default = [
    {
      name    = "kube-proxy"
      version = "v1.29.0-eksbuild.1"
    },
    {
      name    = "vpc-cni"
      version = "v1.16.0-eksbuild.1"
    },
    {
      name    = "coredns"
      version = "v1.11.1-eksbuild.4"
    },
    {
      name    = "aws-ebs-csi-driver"
      version = "v1.26.1-eksbuild.1"
    }
  ]
}

resource "aws_eks_addon" "addons" {
  for_each          = { for addon in var.addons : addon.name => addon }
  cluster_name      = aws_eks_cluster.eks_windows.id
  addon_name        = each.value.name
  addon_version     = each.value.version
  resolve_conflicts_on_create = "OVERWRITE"

  configuration_values = each.value.name == "vpc-cni" ? jsonencode({ 
     env = { 
       ANNOTATE_POD_IP = true 
     } 
   }) : null
}