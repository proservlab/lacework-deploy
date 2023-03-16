output "id" {
    value = module.id.id
}

output "config" {
    value = var.config
}

output "public_ips" {
    value = {
        attacker_http_listener = local.attacker_http_listener
        attacker_reverse_shell = local.attacker_reverse_shell
        attacker_log4shell = local.attacker_log4shell
        attacker_port_forward = local.attacker_port_forward
        target_log4shell = local.target_log4shell
    }
}