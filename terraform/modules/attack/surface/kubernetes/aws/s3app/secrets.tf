resource "kubernetes_secret" "this" {
  metadata {
    name = "${local.app_name}-env-vars"
    namespace = local.app_namespace
  }

  data = {
    BUCKET_NAME = aws_s3_bucket.dev.id
  }

  type = "Opaque"
}