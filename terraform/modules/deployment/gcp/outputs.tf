output "attacker-gce" {
    value = try(module.attacker-gce[0].instances,{})
}

output "target-gce" {
    value = try(module.target-gce[0].instances,{})
}