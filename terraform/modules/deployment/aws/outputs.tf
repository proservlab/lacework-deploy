output "attacker-ec2" {
    value = try(module.attacker-ec2[0].instances,{})
}

output "target-ec2" {
    value = try(module.target-ec2[0].instances,{})
}


output "attacker-eks-services" {
    value = flatten([
        try(module.attacker-vulnerable-kubernetes-authapp[0].services,[]),
        try(module.attacker-vulnerable-kubernetes-s3app[0].services,[]),
        try(attacker-vulnerable-kubernetes-root-mount-fs-pod[0].services,[]),
        try(attacker-vulnerable-kubernetes-privileged-pod[0].services,[]),
        try(attacker-vulnerable-kubernetes-log4j-app[0].services,[]),
        try(attacker-vulnerable-kubernetes-rdsapp[0].services,[]),
        try(attacker-vulnerable-kubernetes-voteapp[0].services,[]),
        try(attacker-kubernetes-app[0].services,[]),
        try(attacker-kubernetes-app-windows[0].services,[]),
    ])
}

output "target-eks-services" {
    value = flatten([
        try(module.target-vulnerable-kubernetes-authapp[0].services,[]),
        try(module.target-vulnerable-kubernetes-s3app[0].services,[]),
        try(target-vulnerable-kubernetes-root-mount-fs-pod[0].services,[]),
        try(target-vulnerable-kubernetes-privileged-pod[0].services,[]),
        try(target-vulnerable-kubernetes-log4j-app[0].services,[]),
        try(target-vulnerable-kubernetes-rdsapp[0].services,[]),
        try(target-vulnerable-kubernetes-voteapp[0].services,[]),
        try(target-kubernetes-app[0].services,[]),
        try(target-kubernetes-app-windows[0].services,[]),
    ])
}