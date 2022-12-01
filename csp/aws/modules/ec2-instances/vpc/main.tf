module "public" {
    count = var.enable_public_vpc == true ? 1 : 0
    source = "./public"

    name = var.name
    environment = var.environment
    allow_all_inter_security_group = var.allow_all_inter_security_group
    public_egress_rules = var.public_egress_rules
    public_ingress_rules = var.public_ingress_rules
    public_network = var.public_network
}

module "private" {
    count = var.enable_private_vpc == true ? 1 : 0
    source = "./private"

    name = var.name
    environment = var.environment
    allow_all_inter_security_group = var.allow_all_inter_security_group
    private_egress_rules = var.private_egress_rules
    private_ingress_rules = var.private_ingress_rules
    private_network = var.private_network
}