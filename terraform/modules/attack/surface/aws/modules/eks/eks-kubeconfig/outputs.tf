output "id" {
    value = module.id.id
}

output "kubeconfig_path" {
    value = data.local_file.kubeconfig.filename
}