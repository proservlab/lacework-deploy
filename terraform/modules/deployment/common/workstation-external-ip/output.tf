output "id" {
    value = module.id.id
}

output "ip" {
    value = local.workstation-external
}

output "cidr" {
    value = local.workstation-external-cidr
}