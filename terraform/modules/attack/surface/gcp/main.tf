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

# ##################################################
# # DEPLOYMENT CONTEXT
# ##################################################

# get current context security group
# data "gcp_security_groups" "public" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
#   tags = {
#     environment = var.config.context.global.environment
#     deployment  = var.config.context.global.deployment
#     public = "true"
#   }
# }

# data "google_compute_addresses" "public" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.gcp.gce.instances) > 0 ) ? 1 : 0
#   filter = "labels.environment:${var.config.context.global.environment} AND labels.deployment:${var.config.context.global.deployment} AND labels.role:default AND labels.public:true"
# }

# data "google_compute_addresses" "public_app" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.gcp.gce.instances) > 0 ) ? 1 : 0
#   filter = "labels.environment:${var.config.context.global.environment} AND labels.deployment:${var.config.context.global.deployment} AND labels.role:app AND labels.public:true"
# }

# data "google_compute_subnetwork" "public" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.aws.ec2.instances) > 0 ) ? 1 : 0
#   name = "${var.config.context.global.environment}-${var.config.context.global.deployment}-public-default-subnetwork"
# }

# data "google_compute_subnetwork" "public_app" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.aws.ec2.instances) > 0 ) ? 1 : 0
#   name = "${var.config.context.global.environment}-${var.config.context.global.deployment}-public-app-subnetwork"
# }

# data "google_compute_addresses" "attacker_public" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.gcp.gce.instances) > 0 ) ? 1 : 0
#   filter = "labels.environment:attacker AND labels.deployment:${var.config.context.global.deployment} AND labels.role:default AND labels.public:true"
# }

# data "google_compute_addresses" "attacker_public_app" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.gcp.gce.instances) > 0 ) ? 1 : 0
#   filter = "labels.environment:attacker AND labels.deployment:${var.config.context.global.deployment} AND labels.role:app AND labels.public:true"
# }

# data "google_compute_subnetwork" "attacker_public" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.aws.ec2.instances) > 0 ) ? 1 : 0
#   name = "attacker-${var.config.context.global.deployment}-public-default-subnetwork"
# }

# data "google_compute_subnetwork" "attacker_public_app" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.aws.ec2.instances) > 0 ) ? 1 : 0
#   name = "attacker-${var.config.context.global.deployment}-public-app-subnetwork"
# }

# data "google_compute_addresses" "target_public" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.gcp.gce.instances) > 0 ) ? 1 : 0
#   filter = "labels.environment:target AND labels.deployment:${var.config.context.global.deployment} AND labels.role:default AND labels.public:true"
# }

# data "google_compute_addresses" "target_public_app" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.gcp.gce.instances) > 0 ) ? 1 : 0
#   filter = "labels.environment:target AND labels.deployment:${var.config.context.global.deployment} AND labels.role:app AND labels.public:true"
# }

# data "google_compute_subnetwork" "target_public" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.aws.ec2.instances) > 0 ) ? 1 : 0
#   name = "target-${var.config.context.global.deployment}-public-default-subnetwork"
# }

# data "google_compute_subnetwork" "target_public_app" {
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gce.enabled == true && length(var.config.context.aws.ec2.instances) > 0 ) ? 1 : 0
#   name = "${var.config.context.global.environment}-${var.config.context.global.deployment}-public-app-subnetwork"
# }

# data "gcp_instances" "public_attacker" {
#   provider = google.attacker
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
#   instance_tags = {
#     environment = "attacker"
#     deployment  = var.config.context.global.deployment
#     public = "true"
#   }
#   instance_state_names = ["running"]
# }

# data "gcp_instances" "public_target" {
#   provider = google.target
#   count = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.aws.ec2.add_trusted_ingress.enabled == true ) ? 1 : 0
#   instance_tags = {
#     environment = "target"
#     deployment  = var.config.context.global.deployment
#     public = "true"
#   }
#   instance_state_names = ["running"]
# }

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
#   for_each = (var.config.context.global.enable_all == true) || (var.config.context.global.disable_all != true && var.config.context.gcp.gcp.add_trusted_ingress.enabled == true ) ? toset(data.gcp_security_groups.public[0].ids) : toset([ for v in []: v ])
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