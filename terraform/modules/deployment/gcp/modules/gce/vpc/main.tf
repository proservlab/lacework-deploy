module "public" {
    count = var.enable_public_vpc == true ? 1 : 0
    source = "./public"

    name = var.name
    environment = var.environment
    deployment = var.deployment
    gcp_location= var.gcp_location
    gcp_project_id= var.gcp_project_id
    role = "default"

    trust_security_group = var.trust_security_group
    public_egress_rules = var.public_egress_rules
    public_ingress_rules = var.public_ingress_rules
    public_network = var.public_network
    public_subnet = var.public_subnet

    service_account_email = var.public_service_account_email
}

module "public-app" {
    count = var.enable_public_app_vpc == true ? 1 : 0
    source = "./public"

    name = var.name
    environment = var.environment
    deployment = var.deployment
    gcp_location= var.gcp_location
    gcp_project_id= var.gcp_project_id
    role = "app"

    trust_security_group = var.trust_security_group
    public_egress_rules = var.public_app_egress_rules
    public_ingress_rules = var.public_app_ingress_rules
    public_network = var.public_app_network
    public_subnet = var.public_app_subnet

    service_account_email = var.public_app_service_account_email
}

module "private" {
    count = var.enable_private_vpc == true ? 1 : 0
    source = "./private"

    name = var.name
    environment = var.environment
    deployment = var.deployment
    gcp_location= var.gcp_location
    gcp_project_id= var.gcp_project_id
    role = "default"
    
    trust_security_group = var.trust_security_group
    private_egress_rules = var.private_egress_rules
    private_ingress_rules = var.private_ingress_rules
    private_network = var.private_network
    private_subnet = var.private_subnet
    private_nat_subnet = var.private_nat_subnet

    service_account_email = var.private_service_account_email
}

module "private-app" {
    count = var.enable_private_app_vpc == true ? 1 : 0
    source = "./private"

    name = var.name
    environment = var.environment
    deployment = var.deployment
    gcp_location= var.gcp_location
    gcp_project_id= var.gcp_project_id
    role = "app"
    
    trust_security_group = var.trust_security_group
    private_egress_rules = var.private_app_egress_rules
    private_ingress_rules = var.private_app_ingress_rules
    private_network = var.private_app_network
    private_subnet = var.private_app_subnet
    private_nat_subnet = var.private_app_nat_subnet

    service_account_email = var.private_app_service_account_email
}