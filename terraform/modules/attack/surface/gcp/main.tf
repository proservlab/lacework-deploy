locals {
  config = var.config
  default_infrastructure_config = var.infrastructure.config[var.config.context.global.environment]
  attacker_infrastructure_config = var.infrastructure.config["attacker"]
  target_infrastructure_config = var.infrastructure.config["target"]

  default_infrastructure_deployed = var.infrastructure.deployed_state[var.config.context.global.environment].context
  attacker_infrastructure_deployed = var.infrastructure.deployed_state["attacker"].context
  target_infrastructure_deployed = var.infrastructure.deployed_state["target"].context

  # target_eks_public_ip = try(["${var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  # attacker_eks_public_ip = try(["${var.infrastructure.deployed_state.attacker.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
}

##################################################
# DEPLOYMENT CONTEXT
##################################################


data "google_compute_zones" "this" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.add_trusted_ingress.enabled == true ) ? 1 : 0
  provider = google.target
  region = local.default_infrastructure_config.context.gcp.region
}

data "google_compute_instance_group" "target_public_default" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.add_trusted_ingress.enabled == true ) ? 1 : 0
  provider = google.target
  name = "target-00000001-public-default-group"
  zone = data.google_compute_zones.this[0].names[0]
}

data "google_compute_instance_group" "target_public_app" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.add_trusted_ingress.enabled == true ) ? 1 : 0
  provider = google.target
  name = "target-00000001-public-app-group"
  zone = data.google_compute_zones.this[0].names[0]
}

data "google_compute_instance_group" "target_private_default" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.add_trusted_ingress.enabled == true ) ? 1 : 0  
  provider = google.target
  name = "target-00000001-private-default-group"
  zone = data.google_compute_zones.this[0].names[0]
}

data "google_compute_instance_group" "target_private_app" {
  count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.add_trusted_ingress.enabled == true ) ? 1 : 0
  provider = google.target
  name = "target-00000001-private-app-group"
  zone = data.google_compute_zones.this[0].names[0]
}

locals {
   target_public_default_instances = [ for compute in can(
      length(
        data.google_compute_instance_group.target_public_default[0].instances
      )
    ) ? data.google_compute_instance_group.target_public_default[0].instances : toset([]) : compute ]
   target_public_app_instances = [ for compute in can(
      length(
        data.google_compute_instance_group.target_public_app[0].instances
      )
    ) ? data.google_compute_instance_group.target_public_app[0].instances : toset([]) : compute ]
   target_private_default_instances = [ for compute in can(
      length(
        data.google_compute_instance_group.target_private_default[0].instances
      )
    ) ? data.google_compute_instance_group.target_private_default[0].instances : toset([]) : compute ]
   target_private_app_instances = [ for compute in can(
      length(
        data.google_compute_instance_group.target_private_app[0].instances
      )
    ) ? data.google_compute_instance_group.target_private_app[0].instances : toset([]) : compute ]
}

data "google_compute_instance" "target_public" {
  for_each = toset(local.target_public_default_instances)
  self_link = each.key
  zone = data.google_compute_zones.this[0].names[0]
}

data "google_compute_instance" "target_public_app" {
  for_each = toset(local.target_public_app_instances)
  self_link = each.key
  zone = data.google_compute_zones.this[0].names[0]
}

data "google_compute_instance" "target_private" {
  for_each = toset(local.target_private_default_instances)
  self_link = each.key
  zone = data.google_compute_zones.this[0].names[0]
}

data "google_compute_instance" "target_private_app" {
  for_each = toset(local.target_private_app_instances)
  self_link = each.key
  zone = data.google_compute_zones.this[0].names[0]
}

##################################################
# GENERAL
##################################################

module "workstation-external-ip" {
  source       = "../general/workstation-external-ip"
}

# ##################################################
# # GCP IAM
# ##################################################

# # create iam users
# module "iam" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.iam.enabled == true ) ? 1 : 0
#   source      = "./modules/iam"
#   environment       = var.config.context.global.environment
#   deployment        = var.config.context.global.deployment
#   region            = var.config.context.aws.region

#   user_policies     = jsondecode(file(var.config.context.aws.iam.user_policies_path))
#   users             = jsondecode(file(var.config.context.aws.iam.users_path))
# }

##################################################
# GCP GCE SECURITY GROUP
##################################################

# append ingress rules
# module "gce-add-trusted-ingress" {
#   for_each = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gcp.gce.add_trusted_ingress.enabled == true ) ? toset(data.gcp_security_groups.public[0].ids) : toset([ for v in []: v ])
#   source        = "./modules/gce/add-trusted-ingress"
#   environment                   = var.config.context.global.environment
#   deployment                    = var.config.context.global.deployment
  
#   security_group_id             = each.key
#   trusted_attacker_source       = var.config.context.gcp.gce.add_trusted_ingress.trust_attacker_source ? flatten([
#     [ for ip in data.gcp_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_gke_public_ip
#   ])  : []
#   trusted_target_source         = var.config.context.gcp.gce.add_trusted_ingress.trust_target_source ? flatten([
#     [ for ip in data.gcp_instances.public_target[0].public_ips: "${ip}/32" ],
#     local.target_gke_public_ip
#   ]) : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = var.config.context.gcp.gce.add_trusted_ingress.additional_trusted_sources
#   trusted_tcp_ports             = var.config.context.gcp.gce.add_trusted_ingress.trusted_tcp_ports
# }

# ##################################################
# # GCP OSCONFIG
# # osconfig tag-based surface config
# ##################################################

# module "ssh-keys" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.ssh_keys.enabled == true ) ? 1 : 0
#   source = "./modules/osconfig/gce/ssh-keys"
#   environment = var.config.context.global.environment
#   deployment  = var.config.context.global.deployment
# }

# module "vulnerable-docker-log4shellspp" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ssm.vulnerable.docker.log4shellapp.enabled == true ) ? 1 : 0
#   source = "./modules/osconfig/gce/vulnerable/docker-log4shellapp"
#   environment = var.config.context.global.environment
#   deployment  = var.config.context.global.deployment
#   listen_port = var.config.context.aws.ssm.vulnerable.docker.log4shellapp.listen_port
# }

# ##################################################
# # Kubernetes General
# ##################################################

# # example of pushing kubernetes deployment via terraform
# module "kubernetes-app" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.app.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/app"
#   environment = var.config.context.global.environment
#   deployment  = var.config.context.global.deployment
# }

# # example of applying pod security policy
# module "kubenetes-psp" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.psp.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/psp"
#   environment = var.config.context.global.environment
#   deployment  = var.config.context.global.deployment
# }

# ##################################################
# # Kubernetes GCP Vulnerable
# ##################################################

# # module "vulnerable-kubernetes-voteapp" {
# #   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
# #   source      = "../kubernetes/aws/vulnerable/voteapp"
# #   environment                   = var.config.context.global.environment
# #   deployment                    = var.config.context.global.deployment
# #   region                        = var.config.context.aws.region
# #   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
# #   secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

# #   vote_service_port             = var.config.context.kubernetes.vulnerable.voteapp.vote_service_port
# #   result_service_port           = var.config.context.kubernetes.vulnerable.voteapp.result_service_port
# #   trusted_attacker_source       = var.config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
# #     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
# #     local.attacker_eks_public_ip
# #   ])  : []
# #   trusted_workstation_source    = [module.workstation-external-ip.cidr]
# #   additional_trusted_sources    = var.config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources
# # }

# ##################################################
# # Kubernetes Vulnerable
# ##################################################

# # module "vulnerable-kubernetes-log4shellapp" {
# #   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.log4shellapp.enabled == true ) ? 1 : 0
# #   source      = "../kubernetes/vulnerable/log4shellapp"
# #   environment                   = var.config.context.global.environment
# #   deployment                    = var.config.context.global.deployment
# #   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

# #   service_port                  = var.config.context.kubernetes.vulnerable.log4shellapp.service_port
# #   trusted_attacker_source       = var.config.context.kubernetes.vulnerable.log4shellapp.trust_attacker_source ? flatten([
# #     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
# #     local.attacker_eks_public_ip
# #   ])  : []
# #   trusted_workstation_source    = [module.workstation-external-ip.cidr]
# #   additional_trusted_sources    = var.config.context.kubernetes.vulnerable.log4shellapp.additional_trusted_sources
# # }

# module "vulnerable-kubernetes-privileged-pod" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/vulnerable/privileged-pod"
#   environment = var.config.context.global.environment
#   deployment  = var.config.context.global.deployment
# }

# module "vulnerable-kubernetes-root-mount-fs-pod" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.kubernetes.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/vulnerable/root-mount-fs-pod"
#   environment = var.config.context.global.environment
#   deployment  = var.config.context.global.deployment
# }