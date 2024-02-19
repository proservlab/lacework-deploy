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
  app_name        = var.app
  app_namespace   = var.app_namespace
  service_account = "authapp"
}

module "deployment" {
  source    = "../../common/terraform-kubernetes-deployment-master"
  namespace = local.app_namespace
  image     = "${aws_ecr_repository.repo.repository_url}:${data.external.hash.result["hash"]}"
  name      = local.app_name
  command   = var.command
  args      = var.args

  service_account_name = kubernetes_service_account.this.metadata[0].name

  deployment_annotations = {
    # "configmap.reloader.stakater.com/reload": "test-configmap"
    "secret.reloader.stakater.com/reload" : kubernetes_secret.this.metadata[0].name
    # "reloader.stakater.com/auto" : "true"
  }

  env_secret = {
    ADMINPWD = kubernetes_secret.this.metadata[0].name
    USERPWD  = kubernetes_secret.this.metadata[0].name
  }

  internal_port = [{
    name          = "container"
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
    "reloader.stakater.com/auto" : "true"
  }
  replicas = 1
  rolling_update = {
    max_surge = 0
    max_unavailable = 1
  }

  depends_on = [
    kubernetes_namespace.this
  ]
}
