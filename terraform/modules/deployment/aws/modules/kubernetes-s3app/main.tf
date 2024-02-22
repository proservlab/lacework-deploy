##################################################
# LOCALS
##################################################

locals {
  app_name      = var.app
  app_namespace = var.app_namespace

  service_account_db_user = var.service_account_db_user
  service_account         = var.service_account
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

module "deployment" {
  source               = "../terraform-kubernetes-deployment-master"
  namespace            = local.app_namespace
  image                = "${aws_ecr_repository.repo.repository_url}:${data.external.hash.result["hash"]}"
  name                 = local.app_name
  command              = var.command
  args                 = var.args
  service_account_name = kubernetes_service_account.web_service.metadata[0].name

  deployment_annotations = {
    # "configmap.reloader.stakater.com/reload": "test-configmap"
    "secret.reloader.stakater.com/reload" : kubernetes_secret.this.metadata[0].name
    # "reloader.stakater.com/auto" : "true"
  }

  env_secret = {
    ADMINPWD    = kubernetes_secret.this.metadata[0].name
    USERPWD     = kubernetes_secret.this.metadata[0].name
    BUCKET_NAME = kubernetes_secret.this.metadata[0].name
  }

  internal_port = [{
    name          = "container"
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
  replicas = 1
  termination_grace_period_seconds = 0

  depends_on = [
    kubernetes_namespace.this,
    kubernetes_service_account.web_service
  ]
}
