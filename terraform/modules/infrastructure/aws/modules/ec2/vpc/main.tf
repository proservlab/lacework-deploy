module "public" {
    count = var.enable_public_vpc == true ? 1 : 0
    source = "./public"

    name = var.name
    environment = var.environment
    deployment = var.deployment
    role = "default"

    trust_security_group = var.trust_security_group
    public_egress_rules = var.public_egress_rules
    public_ingress_rules = var.public_ingress_rules
    public_network = var.public_network
    public_subnet = var.public_subnet
}

module "public-app" {
    count = var.enable_public_app_vpc == true ? 1 : 0
    source = "./public"

    name = var.name
    environment = var.environment
    deployment = var.deployment
    role = "app"

    trust_security_group = var.trust_security_group
    public_egress_rules = var.public_app_egress_rules
    public_ingress_rules = var.public_app_ingress_rules
    public_network = var.public_app_network
    public_subnet = var.public_app_subnet
}

module "private" {
    count = var.enable_private_vpc == true ? 1 : 0
    source = "./private"

    name = var.name
    environment = var.environment
    deployment = var.deployment
    role = "default"
    
    trust_security_group = var.trust_security_group
    private_egress_rules = var.private_egress_rules
    private_ingress_rules = var.private_ingress_rules
    private_network = var.private_network
    private_subnet = var.private_subnet
    private_nat_subnet = var.private_nat_subnet
}

module "private-app" {
    count = var.enable_private_app_vpc == true ? 1 : 0
    source = "./private"

    name = var.name
    environment = var.environment
    deployment = var.deployment
    role = "app"
    
    trust_security_group = var.trust_security_group
    private_egress_rules = var.private_app_egress_rules
    private_ingress_rules = var.private_app_ingress_rules
    private_network = var.private_app_network
    private_subnet = var.private_app_subnet
    private_nat_subnet = var.private_app_nat_subnet
}

# add public/private peering
resource "aws_vpc_peering_connection" "peer-public-private" {
  peer_vpc_id = module.public.vpc.id
  vpc_id      = module.private.vpc.id
  auto_accept = true
}

resource "aws_route" "private_to_public" {
  route_table_id         = module.private.vpc.main_route_table_id
  destination_cidr_block = module.public.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private.id
}

resource "aws_route" "public_to_private" {
  route_table_id         = module.public.vpc.main_route_table_id
  destination_cidr_block = module.private.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private.id
}

resource "aws_security_group_rule" "private_to_public" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.private.sg.id
  source_security_group_id = module.public.sg.id
}

resource "aws_security_group_rule" "public_to_private" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.public.sg.id
  source_security_group_id = module.private.sg.id
}

# add public/private peering for app
resource "aws_vpc_peering_connection" "peer-public-private-app" {
  peer_vpc_id = module.public-app.vpc.id
  vpc_id      = module.private-app.vpc.id
  auto_accept = true
}

resource "aws_route" "private_to_public_app" {
  route_table_id         = module.private-app.vpc.main_route_table_id
  destination_cidr_block = module.public-app.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private-app.id
}

resource "aws_route" "public_to_private_app" {
  route_table_id         = module.public-app.vpc.main_route_table_id
  destination_cidr_block = module.private-app.vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private-app.id
}

resource "aws_security_group_rule" "private_to_public_app" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.private-app.sg.id
  source_security_group_id = module.public-app.sg.id
}

resource "aws_security_group_rule" "public_to_private_app" {
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.public-app.sg.id
  source_security_group_id = module.private-app.sg.id
}