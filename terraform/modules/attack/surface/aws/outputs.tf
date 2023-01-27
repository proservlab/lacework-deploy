output "compromised_credentials" {
    value = try(module.iam[0].access_keys, {})
}