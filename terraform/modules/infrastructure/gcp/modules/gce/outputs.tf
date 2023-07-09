output "vpc" {
    value = module.vpc
}

output "instances" {
    sensitive = false
    value = module.instances
}