resource "kubernetes_secret" "this" {
  metadata {
    name = "${local.app_name}-env-vars"
    namespace = local.app_namespace
  }

  data = {
    bucket_name = aws_s3_bucket.dev.id
  }

  type = "Opaque"
}