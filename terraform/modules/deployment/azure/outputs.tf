output "attacker-ec2" {
    value = try(module.attacker-ec2[0].instances,{})
}

output "target-ec2" {
    value = try(module.target-ec2[0].instances,{})
}