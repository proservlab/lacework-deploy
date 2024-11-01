output "attacker-instances" {
    value = try(module.attacker-ec2[0].instances,{})
}

output "attacker-dns-records" {
    value = try(module.attacker-ec2[0].dns-records,{})
}

output "target-instances" {
    value = try(module.target-ec2[0].instances,{})
}

output "target-dns-records" {
    value = try(module.target-ec2[0].dns-records,{})
}

output "attacker-k8s-services" {
    value = flatten([
        try(module.attacker-vulnerable-kubernetes-authapp[0].services,[]),
        try(module.attacker-vulnerable-kubernetes-s3app[0].services,[]),
        try(module.attacker-vulnerable-kubernetes-root-mount-fs-pod[0].services,[]),
        try(module.attacker-vulnerable-kubernetes-privileged-pod[0].services,[]),
        try(module.attacker-vulnerable-kubernetes-log4j-app[0].services,[]),
        try(module.attacker-vulnerable-kubernetes-rdsapp[0].services,[]),
        try(module.attacker-vulnerable-kubernetes-voteapp[0].services,[]),
        try(module.attacker-kubernetes-app[0].services,[]),
        try(module.attacker-kubernetes-app-windows[0].services,[]),
    ])
}

output "target-k8s-services" {
    value = flatten([
        try(module.target-vulnerable-kubernetes-authapp[0].services,[]),
        try(module.target-vulnerable-kubernetes-s3app[0].services,[]),
        try(module.target-vulnerable-kubernetes-root-mount-fs-pod[0].services,[]),
        try(module.target-vulnerable-kubernetes-privileged-pod[0].services,[]),
        try(module.target-vulnerable-kubernetes-log4j-app[0].services,[]),
        try(module.target-vulnerable-kubernetes-rdsapp[0].services,[]),
        try(module.target-vulnerable-kubernetes-voteapp[0].services,[]),
        try(module.target-kubernetes-app[0].services,[]),
        try(module.target-kubernetes-app-windows[0].services,[]),
    ])
}

output "attacker_private_nat_gw_ip" {
    value = local.attacker_private_nat_gw_ip
}

output "attacker_private_app_nat_gw_ip" {
    value = local.attacker_private_app_nat_gw_ip
}

output "target_private_nat_gw_ip" {
    value = local.target_private_nat_gw_ip
}

output "target_private_app_nat_gw_ip" {
    value = local.target_private_app_nat_gw_ip
}

output "target_iam_access_keys" {
    value = module.target-iam[0].access_keys
}

output "attacker_iam_access_keys" {
    value = module.attacker-iam[0].access_keys
}