# build and push...yes I know this should be a pipeline activity/cloudbuild
data "external" "hash" {
  program = [coalesce(var.hash_script, "${path.module}/hash.sh"), var.source_path]
}

# Build and push the Docker image whenever the hash changes
resource "null_resource" "push" {
  triggers = {
    hash = data.external.hash.result["hash"]
  }

  provisioner "local-exec" {
    command     = <<COMMAND
cd ${var.source_path} && docker build -t ${var.image_name}:${var.tag} . \
&&  echo "${data.aws_ecr_authorization_token.token.password}" | cut -d' ' -f2 | docker login --username AWS --password-stdin "${aws_ecr_repository.repo.repository_url}" \
&& docker tag "${var.image_name}:${var.tag}" "${aws_ecr_repository.repo.repository_url}:${var.tag}" \
&& docker push "${aws_ecr_repository.repo.repository_url}:${var.tag}"
COMMAND
    interpreter = ["bash", "-c"]
  }

  depends_on = [
      aws_ecr_repository.repo, 
      data.aws_ecr_authorization_token.token
  ]
}

# lacework scratch sidecar
# build and push...yes I know this should be a pipeline activity/cloudbuild
data "external" "lacework_hash" {
  program = [coalesce(var.hash_script, "${path.module}/hash.sh"), var.lacework_source_path]
}

# Build and push the Docker image whenever the hash changes
resource "null_resource" "lacework_push" {
  triggers = {
    hash = data.external.lacework_hash.result["hash"]
  }

  provisioner "local-exec" {
    command     = <<COMMAND
cd ${var.lacework_source_path} && docker build -t ${var.lacework_image_name}:${var.lacework_tag} . \
&&  echo "${data.aws_ecr_authorization_token.token.password}" | cut -d' ' -f2 | docker login --username AWS --password-stdin "${aws_ecr_repository.lacework-repo.repository_url}" \
&& docker tag "${var.lacework_image_name}:${var.lacework_tag}" "${aws_ecr_repository.lacework-repo.repository_url}:${var.lacework_tag}" \
&& docker push "${aws_ecr_repository.lacework-repo.repository_url}:${var.lacework_tag}"
COMMAND
    interpreter = ["bash", "-c"]
  }

  depends_on = [
      aws_ecr_repository.lacework-repo, 
      data.aws_ecr_authorization_token.token
  ]
}