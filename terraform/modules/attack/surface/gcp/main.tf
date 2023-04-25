##################################################
# MODULE ID
##################################################

module "id" {
  source = "../../../context/deployment"
}

##################################################
# LOCALS
##################################################

module "default-config" {
  source = "../../../context/attack/surface"
}

locals {
  config = try(length(var.config), {}) == {} ? module.default-config.config : var.config
  enabled = try(length(var.config), {}) == {} ? false : true

  default_infrastructure_config = var.infrastructure.config[local.config.context.global.environment]
  attacker_infrastructure_config = var.infrastructure.config["attacker"]
  target_infrastructure_config = var.infrastructure.config["target"]

  default_infrastructure_deployed = var.infrastructure.deployed_state[local.config.context.global.environment].context
  attacker_infrastructure_deployed = var.infrastructure.deployed_state["attacker"].context
  target_infrastructure_deployed = var.infrastructure.deployed_state["target"].context

  default_instances = try(local.default_infrastructure_deployed.gcp.gce[0].instances, [])
  attacker_instances = try(local.attacker_infrastructure_deployed.gcp.gce[0].instances, [])
  target_instances = try(local.target_infrastructure_deployed.gcp.gce[0].instances, [])

  public_attacker_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.labels.role == "default" && compute.instance.labels.public == "true" ]
  ])

  public_attacker_app_instances = flatten([
    [ for compute in local.attacker_instances: compute.instance if compute.instance.labels.role == "app" && compute.instance.labels.public == "true" ]
  ])

  public_target_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.labels.role == "default" && compute.instance.labels.public == "true" ]
  ])

  public_target_app_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.labels.role == "app" && compute.instance.labels.public == "true" ]
  ])

  # target_eks_public_ip = try(["${var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
  # attacker_eks_public_ip = try(["${var.infrastructure.deployed_state.attacker.context.aws.eks[0].cluster_nat_public_ip}/32"],[])
}

resource "null_resource" "log" {
  triggers = {
    log_message = jsonencode(local.config)
  }

  provisioner "local-exec" {
    command = "echo '${jsonencode(local.config)}'"
  }
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

locals {
  # attacker scenario public ips
  attacker_public_ips = [ 
    for instance in local.public_attacker_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  attacker_app_public_ips = [ 
    for instance in local.public_attacker_app_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  # target scenario public ips
  target_public_ips = [ 
    for instance in local.public_target_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  target_app_public_ips = [ 
    for instance in local.public_target_app_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  public_networks = ((
      local.config.context.global.environment == "attacker" 
      && ( 
        length(local.attacker_public_ips) > 0 
        || length(local.attacker_app_public_ips) > 0
      ) 
    ) || (
      local.config.context.global.environment == "target" 
      && ( 
        length(local.target_public_ips) > 0 
        || length(local.target_app_public_ips) > 0
      ) 
    )) ? true : false
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
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.aws.iam.enabled == true ) ? 1 : 0
#   source      = "./modules/iam"
#   environment       = local.config.context.global.environment
#   deployment        = local.config.context.global.deployment
#   region            = local.config.context.aws.region

#   user_policies     = jsondecode(file(local.config.context.aws.iam.user_policies_path))
#   users             = jsondecode(file(local.config.context.aws.iam.users_path))
# }

##################################################
# GCP GCE SECURITY GROUP
##################################################

# append ingress rules
module "gce-add-trusted-ingress" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.gce.add_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/gce/add-trusted-ingress"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  network                       = try(local.default_infrastructure_deployed.gcp.gce[0].vpc.public_network.name, null)
  trusted_attacker_source       = local.config.context.gcp.gce.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for ip in local.attacker_public_ips: "${ip}/32" ],
    [ for ip in local.attacker_app_public_ips: "${ip}/32" ]
  ])  : []
  trusted_target_source         = local.config.context.gcp.gce.add_trusted_ingress.trust_target_source ? flatten([
    [ for ip in local.target_public_ips: "${ip}/32" ],
    [ for ip in local.target_app_public_ips: "${ip}/32" ]
  ]) : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.gcp.gce.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.config.context.gcp.gce.add_trusted_ingress.trusted_tcp_ports
}

##################################################
# GCP OSCONFIG
# osconfig tag-based surface config
##################################################

module "ssh-keys" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/gce/ssh-keys"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  public_tag = "osconfig_deploy_secret_ssh_public"
  private_tag = "osconfig_deploy_secret_ssh_private"
}

module "vulnerable-docker-log4shellapp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.vulnerable.docker.log4shellapp.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/gce/vulnerable/docker-log4shellapp"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  listen_port = local.config.context.gcp.osconfig.vulnerable.docker.log4shellapp.listen_port

  tag = "osconfig_exec_docker_log4shell_target"
}

module "vulnerable-npm-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/gce/vulnerable/npm-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  listen_port = local.config.context.gcp.osconfig.vulnerable.npm_app.listen_port

  tag = "osconfig_exec_vuln_npm_app_target"
}

module "vulnerable-python3-twisted-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/gce/vulnerable/python3-twisted-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  listen_port = local.config.context.gcp.osconfig.vulnerable.python3_twisted_app.listen_port

  tag = "osconfig_exec_vuln_python3_twisted_app_target"
}

##################################################
# Kubernetes General
##################################################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
}

# example of applying pod security policy
module "kubenetes-psp" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.psp.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/psp"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
}

##################################################
# Kubernetes GCP Vulnerable
##################################################

# module "vulnerable-kubernetes-voteapp" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
#   source      = "../kubernetes/gcp/vulnerable/voteapp"
#   environment                   = local.config.context.global.environment
#   deployment                    = local.config.context.global.deployment
#   region                        = local.config.context.aws.region
#   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
#   secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

#   vote_service_port             = local.config.context.kubernetes.vulnerable.voteapp.vote_service_port
#   result_service_port           = local.config.context.kubernetes.vulnerable.voteapp.result_service_port
#   trusted_attacker_source       = local.config.context.kubernetes.vulnerable.voteapp.trust_attacker_source ? flatten([
#     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_eks_public_ip
#   ])  : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources
# }

# module "vulnerable-kubernetes-log4shellapp" {
#   count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.vulnerable.log4shellapp.enabled == true ) ? 1 : 0
#   source      = "../kubernetes/gcp/vulnerable/log4shellapp"
#   environment                   = local.config.context.global.environment
#   deployment                    = local.config.context.global.deployment
#   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id

#   service_port                  = local.config.context.kubernetes.gcp.vulnerable.log4shellapp.service_port
#   trusted_attacker_source       = local.config.context.kubernetes.gcp.vulnerable.log4shellapp.trust_attacker_source ? flatten([
#     [ for ip in data.aws_instances.public_attacker[0].public_ips: "${ip}/32" ],
#     local.attacker_eks_public_ip
#   ])  : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.config.context.kubernetes.gcp.vulnerable.log4shellapp.additional_trusted_sources
# }

module "vulnerable-kubernetes-privileged-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/vulnerable/privileged-pod"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/vulnerable/root-mount-fs-pod"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
}