output "vote_service" {
     value = try(module.vulnerable-kubernetes-voteapp.vote_service,"")
}

output "result_service" {
     value = try(module.vulnerable-kubernetes-voteapp.result_service,"")
}

output "rdsapp_service" {
     value = try(module.vulnerable-kubernetes-rdsapp.rdsapp_service,"")
}

output "log4shellapp_service" {
     value = try(module.vulnerable-kubernetes-log4shellapp.log4shellapp_service,"")
}