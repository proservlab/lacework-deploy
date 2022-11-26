output "ec2-instances" {
    value = module.ec2-instances
}

output "attacker-instance-reverseshell" {
    value = local.attacker_instance_reverseshell
}

output "attacker-instance-http-listener" {
    value = local.attacker_instance_http_listener
}

output "attacker-instance-log4shell" {
    value = local.attacker_instance_log4shell
}

output "target-instance-log4shell" {
    value = local.attacker_instance_log4shell
}


output "eks" {
    value = module.eks
}