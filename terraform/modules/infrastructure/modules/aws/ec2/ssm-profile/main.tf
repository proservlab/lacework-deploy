# ssm profile
resource "aws_iam_instance_profile" "ec2-iam-profile" {
  name = "ec2_profile_${var.role}_${var.environment}_${var.deployment}"
  role = aws_iam_role.ec2-iam-role.name
}

resource "aws_iam_role" "ec2-iam-role" {
  name        = "ec2_profile_${var.role}_${var.environment}_${var.deployment}"
  description = "The role for EC2 resources"
  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": {
      "Effect": "Allow",
      "Principal": {
          "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  }
  EOF
  tags = {
    environment = var.environment
    deployment = var.deployment
  }
}

resource "aws_iam_policy" "ec2-describe-tags" {
  name        = "ec2_describe_tags_${var.role}_${var.environment}_${var.deployment}"
  description = "ec2 describe tags"

  policy = jsonencode(
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Sid": "DescribeTagsOnly",
                "Effect": "Allow",
                "Action": [
                    "ec2:DescribeTags"
                ],
                "Resource": "*"
            }
        ]
    }
  )
}

resource "aws_iam_role_policy_attachment" "ec2-ssm-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2-instance-policy" {
  role       = aws_iam_role.ec2-iam-role.name
  policy_arn = aws_iam_policy.ec2-describe-tags.arn
}