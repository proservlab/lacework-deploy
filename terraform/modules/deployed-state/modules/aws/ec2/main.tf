data "aws_instances" "public_instances" {
    instance_tags = {
        environment = var.environment
        deployment = var.deployment
        public = "true"
        role = "default"
    }
    instance_state_names = ["running"]
}

data "aws_instances" "public_app_instances" {
    instance_tags = {
        environment = var.environment
        deployment = var.deployment
        public = "true"
        role = "app"
    }
    instance_state_names = ["running"]
}

data "aws_instances" "private_instances" {
    instance_tags = {
        environment = var.environment
        deployment = var.deployment
        public = "false"
        role = "default"
    }
    instance_state_names = ["running"]
}

data "aws_instances" "private_app_instances" {
    instance_tags = {
        environment = var.environment
        deployment = var.deployment
        public = "false"
        role = "default"
    }
    instance_state_names = ["running"]
}

data "aws_vpcs" "public_vpc" {
  tags = {
    environment = var.environment
    deployment = var.deployment
    public = "true"
    role = "default"
  }
}

data "aws_vpcs" "public_app_vpc" {
  tags = {
    environment = var.environment
    deployment = var.deployment
    public = "true"
    role = "app"
  }
}

data "aws_vpcs" "private_vpc" {
  tags = {
    environment = var.environment
    deployment = var.deployment
    public = "false"
    role = "default"
  }
}

data "aws_vpcs" "private_app_vpc" {
  tags = {
    environment = var.environment
    deployment = var.deployment
    public = "false"
    role = "app"
  }
}

data "aws_subnets" "public_subnet" {
  tags = {
    environment = var.environment
    deployment = var.deployment
    public = "true"
    role = "default"
  }
}

data "aws_subnets" "public_app_subnet" {
  tags = {
    environment = var.environment
    deployment = var.deployment
    public = "true"
    role = "app"
  }
}

data "aws_subnets" "private_subnet" {
  tags = {
    environment = var.environment
    deployment = var.deployment
    public = "false"
    role = "default"
  }
}

data "aws_subnets" "private_app_subnet" {
  tags = {
    environment = var.environment
    deployment = var.deployment
    public = "false"
    role = "app"
  }
}