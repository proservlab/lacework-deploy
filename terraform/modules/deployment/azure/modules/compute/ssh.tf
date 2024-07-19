########################################
# INSTANCE SSH KEY - DEFAULT AND APP
########################################

locals {
    ssh_key_path = pathexpand("~/.ssh/azure-${var.environment}-${var.deployment}.pem")
}

# ssh key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = "4096"
}

# ssh key local path
resource "local_file" "ssh-key" {
    content  = tls_private_key.ssh.private_key_pem
    filename = local.ssh_key_path
    file_permission = "0600"
}