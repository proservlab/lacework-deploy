##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../../../context/deployment"
}

##################################################
# LOCALS
##################################################

locals {
    app_name = var.app
    app_namespace = var.app_namespace
}

module "deployment" {
  source        = "../../common/terraform-kubernetes-deployment-master"
  namespace     = local.app_namespace
  image         = var.image
  name          = local.app_name
  command       = var.command
  args          = var.args
  internal_port = [{
    name = "container"
    internal_port = var.container_port
  }]
 security_context_container = [{
      privileged = var.privileged
  }]
  custom_labels = {
    app = local.app_name
  }
  template_annotations = {
    app = local.app_name
  }
  replicas      = 1
  volume_mount  = [{
    volume_name = "test-volume"
    mount_path = "/host"
  }]
  volume_host_path = [{
    volume_name = "test-volume"
    path_on_node = "/"
    type = "Directory"
  }]

  depends_on = [
    kubernetes_namespace.this
  ]
}