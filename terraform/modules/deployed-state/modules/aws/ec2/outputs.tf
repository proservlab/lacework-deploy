output "public_instances" {
    value = {
        ids = data.aws_instances.public_instances.ids
        public_ips = data.aws_instances.public_instances.public_ips
        private_ips = data.aws_instances.public_instances.private_ips
    }
}

output "public_app_instances" {
    value = {
        ids = data.aws_instances.public_app_instances.ids
        public_ips = data.aws_instances.public_app_instances.public_ips
        private_ips = data.aws_instances.public_app_instances.private_ips
    }
}

output "private_instances" {
    value = {
        ids = data.aws_instances.private_instances.ids
        public_ips = data.aws_instances.private_instances.public_ips
        private_ips = data.aws_instances.private_instances.private_ips
    }
}

output "private_app_instances" {
    value = {
        ids = data.aws_instances.private_app_instances.ids
        public_ips = data.aws_instances.private_app_instances.public_ips
        private_ips = data.aws_instances.private_app_instances.private_ips
    }
}

output "public_vpc" {
    value = data.aws_vpcs.public_vpc.ids
}

output "public_app_vpc" {
    value = data.aws_vpcs.public_app_vpc.ids
}

output "private_vpc" {
    value = data.aws_vpcs.private_vpc.ids
}

output "private_app_vpc" {
    value = data.aws_vpcs.private_app_vpc.ids
}

output "public_subnets" {
    value = data.aws_subnets.public_subnet.ids
}

output "public_app_subnets" {
    value = data.aws_subnets.public_app_subnet.ids
}

output "private_subnets" {
    value = data.aws_subnets.private_subnet.ids
}

output "private_app_subnets" {
    value = data.aws_subnets.private_app_subnet.ids
}

output "default_instance_profile" {
    value = "ec2_profile_default_${var.environment}_${var.deployment}"
}

output "app_instance_profile" {
    value = "ec2_profile_app_${var.environment}_${var.deployment}"
}

output "default_instance_role" {
    value = "ec2_profile_default_${var.environment}_${var.deployment}"
}

output "app_instance_role" {
    value = "ec2_profile_app_${var.environment}_${var.deployment}"
}

