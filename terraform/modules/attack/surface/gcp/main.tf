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

##################################################
# GCP IAM
##################################################

# create iam users
module "iam" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.iam.enabled == true ) ? 1 : 0
  source      = "./modules/iam"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  user_policies     = jsondecode(templatefile(local.config.context.gcp.iam.user_policies_path, { environment = local.config.context.global.environment, deployment = local.config.context.global.deployment }))
  users             = jsondecode(templatefile(local.config.context.gcp.iam.users_path, { environment = local.config.context.global.environment, deployment = local.config.context.global.deployment }))
}

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
# GCP OSCONFIG: Surface
##################################################

module "ssh-keys" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-ssh-keys"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  public_tag = "osconfig_deploy_secret_ssh_public"
  private_tag = "osconfig_deploy_secret_ssh_private"
}

module "ssh-user" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-ssh-user"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_ssh_user"

  username = local.config.context.gcp.osconfig.ssh_user.username
  password = local.config.context.gcp.osconfig.ssh_user.password
}

module "gcp-credentials" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.gcp_credentials.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-gcp-credentials"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_secret_gcp_credentials"

  compromised_credentials = try(module.iam[0].access_keys, {})
  compromised_keys_user = local.config.context.gcp.osconfig.gcp_credentials.compromised_keys_user
}

##################################################
# GCP OSCONFIG: Vulnerable Apps
##################################################

module "vulnerable-docker-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.vulnerable.docker.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-docker-log4j-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_docker_log4j_app"

  listen_port = local.config.context.gcp.osconfig.vulnerable.docker.log4j_app.listen_port
}

module "vulnerable-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-log4j-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  tag = "osconfig_deploy_log4j_app"

  listen_port = local.config.context.gcp.osconfig.vulnerable.npm_app.listen_port
}

module "vulnerable-npm-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-npm-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_npm_app"

  listen_port = local.config.context.gcp.osconfig.vulnerable.npm_app.listen_port
}

module "vulnerable-python3-twisted-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-python3-twisted-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  listen_port = local.config.context.gcp.osconfig.vulnerable.python3_twisted_app.listen_port

  tag = "osconfig_deploy_python3_twisted_app"
}

module "vulnerable-cloudsql-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.gcp.osconfig.vulnerable.cloudsql_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-cloudsql-app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_cloudsql_app"

  listen_port = local.config.context.gcp.osconfig.vulnerable.cloudsql_app.listen_port

  db_host = try(local.default_infrastructure_deployed.gcp.cloudsql[0].db_host, null)
  db_name = try(local.default_infrastructure_deployed.gcp.cloudsql[0].db_name, null)
  db_user = try(local.default_infrastructure_deployed.gcp.cloudsql[0].db_user, null)
  db_password = try(local.default_infrastructure_deployed.gcp.cloudsql[0].db_password, null)
  db_port = try(local.default_infrastructure_deployed.gcp.cloudsql[0].db_port, null)
  db_region = try(local.default_infrastructure_deployed.gcp.cloudsql[0].db_region, null)
}

##################################################
# GCP GKE
##################################################

# configure iam access to gke

##################################################
# Kubernetes General
##################################################

# example of pushing kubernetes deployment via terraform
module "kubernetes-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/app"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
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

    # providers = {
    #   kubernetes = kubernetes.main
    #   helm = helm.main
    # }
# }

# vulnerable-kubernetes-rdsapp

module "vulnerable-kubernetes-log4j-app" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/vulnerable/log4j-app"
  environment                   = local.config.context.global.environment
  deployment                    = local.config.context.global.deployment

  service_port                  = local.config.context.kubernetes.gcp.vulnerable.log4j_app.service_port
  trusted_attacker_source       = local.config.context.gcp.gce.add_trusted_ingress.trust_attacker_source ? flatten([
    [ for ip in local.attacker_public_ips: "${ip}/32" ],
    [ for ip in local.attacker_app_public_ips: "${ip}/32" ]
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.config.context.gcp.gce.add_trusted_ingress.additional_trusted_sources

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "vulnerable-kubernetes-privileged-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/vulnerable/privileged-pod"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}

module "vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.config.context.global.enable_all == true) || (local.config.context.global.disable_all != true && local.config.context.kubernetes.gcp.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/vulnerable/root-mount-fs-pod"
  environment = local.config.context.global.environment
  deployment  = local.config.context.global.deployment

  providers = {
    kubernetes = kubernetes.main
    helm = helm.main
  }
}