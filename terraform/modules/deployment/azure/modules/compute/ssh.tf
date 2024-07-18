########################################
# INSTANCE SSH KEY - DEFAULT AND APP
########################################

locals {
    ssh_key_path = pathexpand("~/.ssh/azure-${var.environment}-${var.deployment}.pem")
}

resource "local_file" "ssh-key" {
    content  = tls_private_key.ssh.private_key_pem
    filename = local.ssh_key_path
    file_permission = "0600"
}