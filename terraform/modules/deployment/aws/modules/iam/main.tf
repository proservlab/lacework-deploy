data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

# create users
resource "aws_iam_user" "users" {
  for_each = { for i in var.users : i.name => i }
  name     = each.key

  tags = {
    environment = var.environment
    deployment = var.deployment
  }
}

resource "aws_iam_policy" "policy" {
  for_each = var.user_policies
  name     = each.key
  path        = "/"

  policy = jsonencode(each.value)
}

# policy   = jsonencode(var.user_policies[each.value.policy])
data "aws_iam_policy" "policy" {
  for_each = { for i in var.users : i.name => i if contains(keys(i), "policy") && i.policy != null && i.policy != "" }
  name = each.value.policy

  depends_on = [
    aws_iam_policy.policy
  ]
}

# allow the user to assume the role provided in the config - only if the role value is provided
resource "aws_iam_policy" "assume_role_policy" {
  for_each = { for i in var.users : i.name => i if lookup(i, "role", false) != false }
  name = "user-assume-role-policy-${each.key}-${each.value.role}-${var.environment}-${var.deployment}"
  description = "Allows assuming the provided role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${each.value.role}"
      },
    ]
  })
}

resource "aws_iam_user_policy_attachment" "attach-iam-policy" {
  for_each = { for i in var.users : i.name => i }
  user       = each.key
  policy_arn = data.aws_iam_policy.policy[each.key].arn

  depends_on = [
    aws_iam_user.users
  ]
}

resource "aws_iam_user_policy_attachment" "attach-assume-role-policy" {
  for_each = { for i in var.users : i.name => i if lookup(i, "role", false) != false }
  user       = each.key
  policy_arn = aws_iam_policy.assume_role_policy[each.key].arn

  depends_on = [
    aws_iam_user_policy_attachment.attach-iam-policy,
    aws_iam_user.users
  ]
}

# create access keys
resource "aws_iam_access_key" "user_access_keys" {
  for_each = { for i in var.users : i.name => i }
  user     = each.key

  depends_on = [
    aws_iam_user.users
  ]
}

locals {
  access_keys = { for user in var.users: user.name => {
                    rendered =  <<-EOT
                                AWS_ACCESS_KEY_ID=${aws_iam_access_key.user_access_keys[user.name].id}
                                AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.user_access_keys[user.name].secret}
                                AWS_DEFAULT_REGION=${var.region}
                                AWS_DEFAULT_OUTPUT=json
                                EOT
                  } 
                }
}