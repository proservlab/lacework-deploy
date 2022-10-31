output "key_id" {
    value = aws_kms_external_key.key ? aws_kms_external_key.key.id : null
}

output "target_s3" {
    value = aws_s3_bucket.target ? aws_s3_bucket.target.id : null
}
