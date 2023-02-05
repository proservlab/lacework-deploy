output "id" {
    value = module.id.id
}
output "compromised_credentials" {
    value = try(module.iam[0].access_keys, {})
}