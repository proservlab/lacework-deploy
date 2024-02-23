# output "config" {
#     sensitive = false
#     value = {
#         context = {
#             workstation = {
#                 ip = module.workstation-external-ip.cidr
#             }
#             gcp = {
#                 gce                       = module.gce
#                 gke                       = module.gke
#                 cloudsql                  = module.cloudsql
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