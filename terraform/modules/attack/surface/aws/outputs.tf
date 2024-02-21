# output "id" {
#     value = module.id.id
# }

# output "config" {
#     value = var.config
# }

# output "compromised_credentials" {
#     value = try(module.iam[0].access_keys, {})
# }

# output "ssh_user" {
#     value = try(length(module.ssh-user[0]), "false") != "false" ? {
#         username = module.ssh-user[0].username
#         password = module.ssh-user[0].password
#     } : null
# }

# output "default_provider" {
#     value = {
#         profile                     = local.profile
#         region                      = local.region
#         access_key                  = local.access_key
#         secret_key                  = local.secret_key
#         skip_credentials_validation = true
#         skip_metadata_api_check     = true
#         skip_requesting_account_id  = true
#     }
# }

# output "kubernetes" {
#     value = {
#         vulnerable = {
#             log4j-app = module.vulnerable-kubernetes-log4j-app
#             privileged_pod = module.vulnerable-kubernetes-privileged-pod
#             rds_app         = module.vulnerable-kubernetes-rdsapp
#             vote_app        = module.vulnerable-kubernetes-voteapp
#         }
#     }
# }