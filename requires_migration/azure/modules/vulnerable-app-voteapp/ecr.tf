resource "aws_ecr_repository" "repo" {
    name                 = var.image_name
    image_tag_mutability = "MUTABLE"

    # Encryption configuration
    # encryption_configuration {
    #     encryption_type = "KMS"
    #     kms_key         = aws_kms_key.kms_key.key_id
    # }

    image_scanning_configuration {
        scan_on_push = true
    }
}

# KMS key
# resource "aws_kms_key" "kms_key" {
#   description = "${var.app}-${var.environment} KMS key"
# }

# resource "aws_kms_alias" "kms_key_alias" {
#   name          = "alias/${var.app}Key"
#   target_key_id = aws_kms_key.kms_key.key_id
# }

resource "aws_ecr_lifecycle_policy" "repo-policy" {
  repository = aws_ecr_repository.repo.name

  policy = jsonencode({
  "rules": [
    {
      "rulePriority": 1,
      "description": "Keep image deployed with tag '${var.tag}''",
      "selection": {
        "tagStatus": "tagged",
        "tagPrefixList": ["${var.tag}"],
        "countType": "imageCountMoreThan",
        "countNumber": 1
      },
      "action": {
        "type": "expire"
      }
    },
    {
      "rulePriority": 2,
      "description": "Keep last 2 any images",
      "selection": {
        "tagStatus": "any",
        "countType": "imageCountMoreThan",
        "countNumber": 2
      },
      "action": {
        "type": "expire"
      }
    }
  ]
})
}

data "aws_ecr_authorization_token" "token" {
}