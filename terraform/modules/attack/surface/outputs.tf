output "voteapp_vote_service" {
     value = try(
          join(":",
               [
                    module.vulnerable-kubernetes-voteapp[0].vote_service,
                    module.vulnerable-kubernetes-voteapp[0].vote_service_port
               ]
          )
          ,null
     )
}

output "voteapp_result_service" {
     value = try(
          join(":",
               [
                    module.vulnerable-kubernetes-voteapp[0].result_service,
                    module.vulnerable-kubernetes-voteapp[0].result_service_port
               ]
          )
          ,null
     )
}

output "rdsapp_service" {
     value = try(
          join(":",
               [
                    module.vulnerable-kubernetes-rdsapp[0].rdsapp_service,
                    module.vulnerable-kubernetes-rdsapp[0].rdsapp_service_port
               ]
          )
          ,null
     )
}

output "log4shellapp_service" {
     value = try(
          join(":",
               [
                    module.vulnerable-kubernetes-log4shellapp[0].log4shellapp_service,
                    module.vulnerable-kubernetes-log4shellapp[0].log4shellapp_service_port
               ]
          )
          ,null
     )
}

output "compromised_credentials" {
    value = module.iam[0].access_keys
}