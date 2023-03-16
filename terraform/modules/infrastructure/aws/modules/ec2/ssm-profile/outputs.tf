output "ec2-iam-profile" {
  value = aws_iam_instance_profile.ec2-iam-profile
}

output "ec2-instance-role" {
  value = aws_iam_role.ec2-iam-role
}