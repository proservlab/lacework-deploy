

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