output "attacker-compute" {
    value = try(module.attacker-compute[0].instances,{})
}

output "target-compute" {
    value = try(module.target-compute[0].instances,{})
}