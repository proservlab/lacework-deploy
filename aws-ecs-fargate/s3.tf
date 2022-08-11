resource "aws_s3_bucket" "lb_logs" {
  bucket = "proservlab-lb-logs"
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.lb_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_acl" "terraform_state" {
  bucket = aws_s3_bucket.lb_logs.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.lb_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.lb_logs.bucket

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions
data "aws_elb_service_account" "main" {}

resource "aws_s3_bucket_policy" "allow_elb_logging" {
  bucket = aws_s3_bucket.lb_logs.bucket
  policy = jsonencode(
      {
        "Version": "2012-10-17",
        "Id": "aws-lb-logging-1660242946927",
        "Statement": [
            {
                "Sid": "Stmt1660242946927",
                "Effect": "Allow",
                "Principal": {
                    "AWS": "${data.aws_elb_service_account.main.arn}"
                },
                "Action": "s3:PutObject",
                "Resource": "${aws_s3_bucket.lb_logs.arn}/*"
            },
            {
                "Sid": "AWSLogDeliveryWrite",
                "Effect": "Allow",
                "Principal": {
                    "Service": "delivery.logs.amazonaws.com"
                },
                "Action": "s3:PutObject",
                "Resource": "${aws_s3_bucket.lb_logs.arn}/*",
                "Condition": {
                    "StringEquals": {
                        "s3:x-amz-acl": "bucket-owner-full-control"
                    }
                }
            },
            {
                "Sid": "AWSLogDeliveryAclCheck",
                "Effect": "Allow",
                "Principal": {
                    "Service": "delivery.logs.amazonaws.com"
                },
                "Action": "s3:GetBucketAcl",
                "Resource": "${aws_s3_bucket.lb_logs.arn}"
            }
        ]
    })
}