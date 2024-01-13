output "username" {
    value = var.username
}

output "password" {
    value = module.payload.outputs["password"]
}