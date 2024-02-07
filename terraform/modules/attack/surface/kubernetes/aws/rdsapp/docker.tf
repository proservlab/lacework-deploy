# build and push...yes I know this should be a pipeline activity/cloudbuild
data "external" "hash" {
  program = [coalesce(var.hash_script, "${path.module}/hash.sh"), "${path.module}/${var.source_path}"]
}

# Build and push the Docker image whenever the hash changes
resource "null_resource" "push" {
  triggers = {
    hash = data.external.hash.result["hash"]
  }

  provisioner "local-exec" {
    command     = <<COMMAND
cd "${path.module}/${var.source_path}" && DOCKER_BUILDKIT=1 docker build -t ${var.image_name}:${data.external.hash.result["hash"]} . \
&&  echo "${data.aws_ecr_authorization_token.token.password}" | cut -d' ' -f2 | docker login --username AWS --password-stdin "${aws_ecr_repository.repo.repository_url}" \
&& docker tag "${var.image_name}:${data.external.hash.result["hash"]}" "${aws_ecr_repository.repo.repository_url}:${data.external.hash.result["hash"]}" \
&& docker push "${aws_ecr_repository.repo.repository_url}:${data.external.hash.result["hash"]}"
COMMAND
    interpreter = ["bash", "-c"]
  }

  depends_on = [
      aws_ecr_repository.repo, 
      data.aws_ecr_authorization_token.token
  ]
}