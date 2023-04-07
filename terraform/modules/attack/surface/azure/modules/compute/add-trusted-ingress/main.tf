resource "azurerm_network_security_rule" "attacker_ingress_rules" {
  name                        = "sg-ingress-${var.environment}-${var.deployment}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "${var.trusted_tcp_ports.from_port}-${var.trusted_tcp_ports.to_port}"
  source_address_prefixes       = flatten([
    var.trusted_attacker_source,
    var.trusted_target_source,
    var.trusted_workstation_source,
    var.additional_trusted_sources
  ])
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group
  network_security_group_name = var.security_group
}