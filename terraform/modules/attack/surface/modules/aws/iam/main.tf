# create users
resource "aws_iam_user" "users" {
  for_each = { for i in var.users : i.name => i }
  name     = each.key

  tags = {
    environment = var.environment
  }
}

# add inline policy to user - this could be improved with roles
resource "aws_iam_user_policy" "user_policies" {
  for_each = { for i in var.users : i.name => i }
  name     = "iam-policy-${var.environment}-${each.value.name}"
  user     = each.key
  policy   = jsonencode(var.user_policies[each.value.policy])

  depends_on = [
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

# credentials template for each user - could be improved
data "template_file" "access_keys" {
  for_each = { for i in var.users : i.name => i }
  template = <<-EOT
    AWS_ACCESS_KEY_ID=${aws_iam_access_key.user_access_keys[each.key].id}
    AWS_SECRET_ACCESS_KEY=${aws_iam_access_key.user_access_keys[each.key].secret}
    AWS_DEFAULT_REGION=${var.region}
    AWS_DEFAULT_OUTPUT=json
    EOT
}