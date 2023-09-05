provider "aws" {
  profile = var.default_aws_profile
}

# Assume the new role using aliased provider
provider "aws" {
    alias  = "generated_role"
    profile = var.default_aws_profile

    dynamic "assume_role" {
        for_each = var.assume_role_apply ? [1] : []
        content {
            role_arn = aws_iam_role.generated_role[0].arn
        }
    }
}