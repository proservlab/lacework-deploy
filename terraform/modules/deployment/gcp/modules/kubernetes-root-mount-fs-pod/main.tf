##################################################
# LOCALS
##################################################

locals {
    app_name = var.app
    app_namespace = var.app_namespace
}

module "deployment" {
  source        = "../../../common/terraform-kubernetes-deployment-master"
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
      allow_privilege_escalation = var.allow_privilege_escalation
      privileged = var.privileged
  }]
  custom_labels = {
    app = local.app_name
  }
  template_annotations = {
    app = local.app_name
  }
  replicas      = 1
  termination_grace_period_seconds = 0

  depends_on = [
    kubernetes_namespace.this
  ]
}

