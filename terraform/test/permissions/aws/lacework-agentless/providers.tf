provider "aws" {
  # profile = var.default_aws_profile
  region = var.default_aws_region
}

# Assume the new role using aliased provider
provider "aws" {
    alias  = "generated_role"
    # profile = var.default_aws_profile
    region = var.default_aws_region

    # dynamic "assume_role" {
    #     for_each = var.create_and_assume_role ? [1] : []
    #     content {
    #         role_arn = aws_iam_role.generated_role[0].arn
    #     }
    # }
}