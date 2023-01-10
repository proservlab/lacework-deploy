output "key_id" {
    value = local.enable_attacker ? aws_kms_external_key.key[0].id : null
}

output "target_s3" {
    value = local.enable_target ? aws_s3_bucket.target[0].id : null
}
