##################################################
# LOCALS
##################################################

locals {
  app_name = var.app
  app_namespace = var.app_namespace
}

data "aws_caller_identity" "current" {}

data "aws_availability_zones" "available" {}

module "deployment" {
  source        = "../../../common/terraform-kubernetes-deployment-master"
  namespace     = local.app_namespace
  image         = "${aws_ecr_repository.repo.repository_url}:${data.external.hash.result["hash"]}"
  name          = local.app_name
  command       = var.command
  args          = var.args
  service_account_name = "database"
  env           = {
                      "DB_APP_URL" = split(":", aws_db_instance.database.endpoint)[0]
                      "DB_USER_NAME" = var.service_account_db_user
                      "DB_NAME" = var.database_name
                      "DB_PORT" = var.database_port
                      "DB_REGION" = var.region
                  }
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
    kubernetes_job_v1.database_bootstrap,
    kubernetes_namespace.this
  ]
}