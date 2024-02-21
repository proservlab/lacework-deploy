# output "id" {
#     value = module.id.id
# }

# output "config" {
#     value = {
#         context = {
#             workstation = {
#                 ip = module.workstation-external-ip.cidr
#             }
#             aws = {
#                 ec2                       = module.ec2
#                 eks                       = module.eks
#                 rds                       = module.rds
#             }
#         }
#     }
# }

# output "workstation_ip" {
#     value = module.workstation-external-ip.cidr
# }

# output "infrastructure-config" {
#     value = var.config
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