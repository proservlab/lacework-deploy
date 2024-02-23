locals {
  target_attacksurface_config = var.target_attacksurface_config
  target_instances = try(module.target-gce[0].instances, [])

  public_target_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.labels.role == "default" && compute.instance.labels.public == "true" ]
  ])

  public_target_app_instances = flatten([
    [ for compute in local.target_instances: compute.instance if compute.instance.labels.role == "app" && compute.instance.labels.public == "true" ]
  ])

  target_gke_public_ip = local.target_infrastructure_config.context.gcp.gke.enabled ? ["${module.target-eks[0].cluster_nat_public_ip}/32"] : []
}

##################################################
# DEPLOYMENT CONTEXT
##################################################

locals {
  # target scenario public ips
  target_public_ips = [ 
    for instance in local.public_target_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]

  target_app_public_ips = [ 
    for instance in local.public_target_app_instances:  instance.network_interface[0].access_config[0].nat_ip
    if lookup(try(instance.network_interface[0].access_config[0], {}), "nat_ip", "false") != "false" 
  ]
}

##################################################
# GCP IAM
##################################################

# create iam users
module "target-iam" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.iam.enabled == true ) ? 1 : 0
  source      = "./modules/iam"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  gcp_project_id                = local.target_infrastructure_config.context.gcp.project_id
  gcp_location                  = local.target_infrastructure_config.context.gcp.region

  user_policies     = jsondecode(templatefile(local.target_attacksurface_config.context.gcp.iam.user_policies_path, { environment = local.target_attacksurface_config.context.global.environment, deployment = local.target_attacksurface_config.context.global.deployment }))
  users             = jsondecode(templatefile(local.target_attacksurface_config.context.gcp.iam.users_path, { environment = local.target_attacksurface_config.context.global.environment, deployment = local.target_attacksurface_config.context.global.deployment }))

  providers = {
    google = google.target
  }
}

##################################################
# GCP GCE SECURITY GROUP
##################################################

# append ingress rules
module "target-gce-add-trusted-ingress" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.gce.add_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/gce-add-trusted-ingress"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  role                          = "default"
  network                       = try(module.target-gce[0].vpc.public_network.name, null)
  trusted_target_source       = local.target_attacksurface_config.context.gcp.gce.add_trusted_ingress.trust_target_source ? flatten([
    [ for ip in local.target_public_ips: "${ip}/32" ],
    [ for ip in local.target_app_public_ips: "${ip}/32" ],
    local.target_gke_public_ip
  ])  : []
  trusted_attacker_source         = local.target_attacksurface_config.context.gcp.gce.add_trusted_ingress.trust_target_source ? flatten([
    [ for ip in local.target_public_ips: "${ip}/32" ],
    [ for ip in local.target_app_public_ips: "${ip}/32" ],
    local.attacker_gke_public_ip
  ]) : []
  trusted_workstation_source    = local.target_attacksurface_config.context.gcp.gce.add_trusted_ingress.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources    = local.target_attacksurface_config.context.gcp.gce.add_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.target_attacksurface_config.context.gcp.gce.add_trusted_ingress.trusted_tcp_ports

  providers = {
    google = google.target
  }
}

module "target-gce-add-trusted-app-ingress" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.gce.add_app_trusted_ingress.enabled == true ) ? 1 : 0
  source        = "./modules/gce-add-trusted-ingress"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  role                          = "app"
  network                       = try(module.target-gce[0].vpc.public_app_network.name, null)
  trusted_target_source       = local.target_attacksurface_config.context.gcp.gce.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for ip in local.target_public_ips: "${ip}/32" ],
    [ for ip in local.target_app_public_ips: "${ip}/32" ],
    local.target_gke_public_ip
  ])  : []
  trusted_attacker_source         = local.target_attacksurface_config.context.gcp.gce.add_app_trusted_ingress.trust_target_source ? flatten([
    [ for ip in local.target_public_ips: "${ip}/32" ],
    [ for ip in local.target_app_public_ips: "${ip}/32" ],
    local.attacker_gke_public_ip
  ]) : []
  trusted_workstation_source    = local.target_attacksurface_config.context.gcp.gce.add_app_trusted_ingress.trust_workstation_source ? [ module.workstation-external-ip.cidr ] : []
  additional_trusted_sources    = local.target_attacksurface_config.context.gcp.gce.add_app_trusted_ingress.additional_trusted_sources
  trusted_tcp_ports             = local.target_attacksurface_config.context.gcp.gce.add_app_trusted_ingress.trusted_tcp_ports

  providers = {
    google = google.target
  }
}

##################################################
# GCP OSCONFIG: Surface
##################################################

module "target-ssh-keys" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.osconfig.ssh_keys.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-ssh-keys"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  public_tag = "osconfig_deploy_secret_ssh_public"
  private_tag = "osconfig_deploy_secret_ssh_private"

  ssh_public_key_path = local.target_attacksurface_config.context.gcp.osconfig.ssh_keys.ssh_public_key_path
  ssh_private_key_path = local.target_attacksurface_config.context.gcp.osconfig.ssh_keys.ssh_private_key_path
  ssh_authorized_keys_path = local.target_attacksurface_config.context.gcp.osconfig.ssh_keys.ssh_authorized_keys_path

  providers = {
    google = google.target
  }
}

module "target-ssh-user" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.osconfig.ssh_user.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-ssh-user"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_ssh_user"

  username = local.target_attacksurface_config.context.gcp.osconfig.ssh_user.username
  password = local.target_attacksurface_config.context.gcp.osconfig.ssh_user.password

  providers = {
    google = google.target
  }
}

module "target-gcp-credentials" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.osconfig.gcp_credentials.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-gcp-credentials"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_secret_gcp_credentials"

  compromised_credentials = try(module.iam[0].access_keys, {})
  compromised_keys_user = local.target_attacksurface_config.context.gcp.osconfig.gcp_credentials.compromised_keys_user

  depends_on = [ 
    module.iam 
  ]

  providers = {
    google = google.target
  }
}

##################################################
# GCP OSCONFIG: Vulnerable Apps
##################################################

module "target-vulnerable-docker-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.osconfig.vulnerable.docker.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-docker-log4j-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_docker_log4j_app"

  listen_port = local.target_attacksurface_config.context.gcp.osconfig.vulnerable.docker.log4j_app.listen_port

  providers = {
    google = google.target
  }
}

module "target-vulnerable-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.osconfig.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-log4j-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region
  
  tag = "osconfig_deploy_log4j_app"

  listen_port = local.target_attacksurface_config.context.gcp.osconfig.vulnerable.log4j_app.listen_port

  providers = {
    google = google.target
  }
}

module "target-vulnerable-npm-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.osconfig.vulnerable.npm_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-npm-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_npm_app"

  listen_port = local.target_attacksurface_config.context.gcp.osconfig.vulnerable.npm_app.listen_port

  providers = {
    google = google.target
  }
}

module "target-vulnerable-python3-twisted-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.osconfig.vulnerable.python3_twisted_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-python3-twisted-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  listen_port = local.target_attacksurface_config.context.gcp.osconfig.vulnerable.python3_twisted_app.listen_port

  tag = "osconfig_deploy_python3_twisted_app"

  providers = {
    google = google.target
  }
}

module "target-vulnerable-cloudsql-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.gcp.osconfig.vulnerable.cloudsql_app.enabled == true ) ? 1 : 0
  source = "./modules/osconfig/deploy-cloudsql-app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment
  gcp_project_id = local.default_infrastructure_config.context.gcp.project_id
  gcp_location = local.default_infrastructure_config.context.gcp.region

  tag = "osconfig_deploy_cloudsql_app"

  listen_port = local.target_attacksurface_config.context.gcp.osconfig.vulnerable.cloudsql_app.listen_port

  db_host = try(module.target-cloudsql[0].db_host, null)
  db_name = try(module.target-cloudsql[0].db_name, null)
  db_user = try(module.target-cloudsql[0].db_user, null)
  db_iam_user = try(module.target-cloudsql[0].db_iam_user, null)
  db_password = try(module.target-cloudsql[0].db_password, null)
  db_port = try(module.target-cloudsql[0].db_port, null)
  db_region = try(module.target-cloudsql[0].db_region, null)
  db_private_ip = try(module.target-cloudsql[0].db_private_ip, null)
  db_public_ip = try(module.target-cloudsql[0].db_public_ip, null)

  providers = {
    google = google.target
  }
}

##################################################
# GCP GKE
##################################################

# configure iam access to gke

##################################################
# Kubernetes General
##################################################

# example of pushing kubernetes deployment via terraform
module "target-kubernetes-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.gcp.app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/app"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    google = google.target
    restapi = restapi.main
  }
}

##################################################
# Kubernetes GCP Vulnerable
##################################################

# module "target-vulnerable-kubernetes-voteapp" {
#   count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.enabled == true) ? 1 : 0
#   source      = "../kubernetes/gcp/vulnerable/voteapp"
#   environment                   = local.target_attacksurface_config.context.global.environment
#   deployment                    = local.target_attacksurface_config.context.global.deployment
#   region                        = local.target_attacksurface_config.context.aws.region
#   cluster_vpc_id                = var.infrastructure.deployed_state.target.context.aws.eks[0].cluster_vpc_id
#   secret_credentials            = try(module.iam[0].access_keys["clue.burnetes@interlacelabs"].rendered,"")

#   vote_service_port             = local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.vote_service_port
#   result_service_port           = local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.result_service_port
#   trusted_target_source       = local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.trust_target_source ? flatten([
#     [ for ip in data.aws_instances.public_target[0].public_ips: "${ip}/32" ],
#     local.target_eks_public_ip
#   ])  : []
#   trusted_workstation_source    = [module.workstation-external-ip.cidr]
#   additional_trusted_sources    = local.target_attacksurface_config.context.kubernetes.vulnerable.voteapp.additional_trusted_sources

    # providers = {
    #   kubernetes = kubernetes.target
    #   helm = helm.target
    # }
# }

# vulnerable-kubernetes-rdsapp

module "target-vulnerable-kubernetes-log4j-app" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.gcp.vulnerable.log4j_app.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/log4j-app"
  environment                   = local.target_attacksurface_config.context.global.environment
  deployment                    = local.target_attacksurface_config.context.global.deployment

  service_port                  = local.target_attacksurface_config.context.kubernetes.gcp.vulnerable.log4j_app.service_port
  trusted_target_source       = local.target_attacksurface_config.context.gcp.gce.add_trusted_ingress.trust_target_source ? flatten([
    [ for ip in local.target_public_ips: "${ip}/32" ],
    [ for ip in local.target_app_public_ips: "${ip}/32" ]
  ])  : []
  trusted_workstation_source    = [module.workstation-external-ip.cidr]
  additional_trusted_sources    = local.target_attacksurface_config.context.gcp.gce.add_trusted_ingress.additional_trusted_sources

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    google = google.target
    restapi = restapi.main
  }
}

module "target-vulnerable-kubernetes-privileged-pod" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.gcp.vulnerable.privileged_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/privileged-pod"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    google = google.target
    restapi = restapi.main
  }
}

module "target-vulnerable-kubernetes-root-mount-fs-pod" {
  count = (local.target_attacksurface_config.context.global.enable_all == true) || (local.target_attacksurface_config.context.global.disable_all != true && local.target_attacksurface_config.context.kubernetes.gcp.vulnerable.root_mount_fs_pod.enabled == true ) ? 1 : 0
  source      = "../kubernetes/gcp/root-mount-fs-pod"
  environment = local.target_attacksurface_config.context.global.environment
  deployment  = local.target_attacksurface_config.context.global.deployment

  providers = {
    kubernetes = kubernetes.target
    helm = helm.target
    google = google.target
    restapi = restapi.main
  }
}