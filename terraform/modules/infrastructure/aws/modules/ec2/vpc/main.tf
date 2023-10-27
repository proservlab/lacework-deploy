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

    name = "${var.name}-app"
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

    name = "${var.name}-app"
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
  count = var.enable_public_vpc == true && var.enable_private_vpc == true ? 1 : 0
  peer_vpc_id = module.public[0].vpc.id
  vpc_id      = module.private[0].vpc.id
  auto_accept = true

  tags = {
    environment = var.environment
    deployment = var.deployment
    Name = "peer-${var.environment}-${var.deployment}"
    Side = "Requester"
  }

  depends_on = [ 
    module.public,
    module.private
  ]
}

resource "aws_vpc_peering_connection_accepter" "peer-public-private" {
  count = var.enable_public_vpc == true && var.enable_private_vpc == true ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private[0].id
  auto_accept               = true

  tags = {
    environment = var.environment
    deployment = var.deployment
    Name = "accepter-${var.environment}-${var.deployment}"
    Side = "Accepter"
  }

  depends_on = [ 
    module.public,
    module.private
  ]
}

resource "aws_vpc_peering_connection_options" "peer-public-private" {
  count = var.enable_public_vpc == true && var.enable_private_vpc == true ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer-public-private[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [ 
    module.public,
    module.private
  ]
}

resource "aws_route" "private_to_public" {
  count = var.enable_public_vpc == true && var.enable_private_vpc == true ? 1 : 0
  route_table_id         = module.private[0].route_table.id
  destination_cidr_block = module.public[0].vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private[0].id

  depends_on = [ 
    module.public,
    module.private
  ]
}

resource "aws_route" "public_to_private" {
  count = var.enable_public_vpc == true && var.enable_private_vpc == true ? 1 : 0
  route_table_id         = module.public[0].route_table.id 
  destination_cidr_block = module.private[0].vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private[0].id

  depends_on = [ 
    module.public,
    module.private
  ]
}

resource "aws_security_group_rule" "private_to_public" {
  count = var.enable_public_vpc == true && var.enable_private_vpc == true ? 1 : 0
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.private[0].sg.id
  source_security_group_id = module.public[0].sg.id

  depends_on = [ 
    module.public,
    module.private
  ]
}

resource "aws_security_group_rule" "public_to_private" {
  count = var.enable_public_vpc == true && var.enable_private_vpc == true ? 1 : 0
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.public[0].sg.id
  source_security_group_id = module.private[0].sg.id

  depends_on = [ 
    module.public,
    module.private
  ]
}

# add public/private peering for app
resource "aws_vpc_peering_connection" "peer-public-private-app" {
  count = var.enable_public_app_vpc == true && var.enable_private_app_vpc == true ? 1 : 0
  peer_vpc_id = module.public-app[0].vpc.id
  vpc_id      = module.private-app[0].vpc.id
  auto_accept = true

  tags = {
    environment = var.environment
    deployment = var.deployment
    Name = "peer-app-${var.environment}-${var.deployment}"
    Side = "Requester"
  }

  depends_on = [ 
    module.public-app,
    module.private-app
  ]
}

resource "aws_vpc_peering_connection_accepter" "peer-public-private-app" {
  count = var.enable_public_app_vpc == true && var.enable_private_app_vpc == true ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private-app[0].id
  auto_accept               = true

  tags = {
    environment = var.environment
    deployment = var.deployment
    Name = "accepter-app-${var.environment}-${var.deployment}"
    Side = "Accepter"
  }

  depends_on = [ 
    module.public-app,
    module.private-app
  ]
}

resource "aws_vpc_peering_connection_options" "peer-public-private-app" {
  count = var.enable_public_app_vpc == true && var.enable_private_app_vpc == true ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection_accepter.peer-public-private-app[0].id

  requester {
    allow_remote_vpc_dns_resolution = true
  }

  depends_on = [ 
    module.public-app,
    module.private-app
  ]
}

resource "aws_route" "private_to_public_app" {
  count = var.enable_public_app_vpc == true && var.enable_private_app_vpc == true ? 1 : 0
  route_table_id         = module.private-app[0].route_table.id
  destination_cidr_block = module.public-app[0].vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private-app[0].id
  
  depends_on = [ 
    module.public-app,
    module.private-app
  ]
}

resource "aws_route" "public_to_private_app" {
  count = var.enable_public_app_vpc == true && var.enable_private_app_vpc == true ? 1 : 0
  route_table_id         = module.public-app[0].route_table.id
  destination_cidr_block = module.private-app[0].vpc.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.peer-public-private-app[0].id

  depends_on = [ 
    module.public-app,
    module.private-app
  ]
}

resource "aws_security_group_rule" "private_to_public_app" {
  count = var.enable_public_app_vpc == true && var.enable_private_app_vpc == true ? 1 : 0
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.private-app[0].sg.id
  source_security_group_id = module.public-app[0].sg.id

  depends_on = [ 
    module.public-app,
    module.private-app
  ]
}

resource "aws_security_group_rule" "public_to_private_app" {
  count = var.enable_public_app_vpc == true && var.enable_private_app_vpc == true ? 1 : 0
  type                     = "ingress"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = module.public-app[0].sg.id
  source_security_group_id = module.private-app[0].sg.id

  depends_on = [ 
    module.public-app,
    module.private-app
  ]
}