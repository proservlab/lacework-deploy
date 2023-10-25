output "kubeconfig_path" {
    value = data.local_file.kubeconfig.filename
}