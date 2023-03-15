output "id" {
    value = module.id.id
}

output "config" {
    value = var.config
}

output "compromised_credentials" {
    value = try(module.iam[0].access_keys, {})
}

output "default_provider" {
    value = {
        profile                     = local.profile
        region                      = local.region
        access_key                  = local.access_key
        secret_key                  = local.secret_key
        skip_credentials_validation = true
        skip_metadata_api_check     = true
        skip_requesting_account_id  = true
    }
}