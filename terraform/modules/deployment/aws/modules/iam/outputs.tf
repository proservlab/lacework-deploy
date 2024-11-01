output "users" {
    value = aws_iam_user.users
}
output "access_keys" {
    value = nonsensitive(local.access_keys)
}