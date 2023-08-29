output "target-gcp-instances" {
  sensitive = false
  value = nonsensitive([
    for gce in can(length(module.target-gcp-infrastructure.config.context.gcp.gce)) ? module.target-gcp-infrastructure.config.context.gcp.gce : [] :
    [
      for compute in gce.instances : {
        id         = compute.instance.id
        name       = compute.instance.labels.name
        private_ip = compute.instance.network_interface.0.network_ip
        public_ip  = compute.instance.network_interface.0.access_config.0.nat_ip
        labels     = { for k, v in compute.instance.labels : k => v if v != "false" }
        project_id = var.target_gcp_project
        region     = var.target_gcp_region
      }
    ]
  ][0])
}

output "attacker-gcp-instances" {
  sensitive = false
  value = nonsensitive([
    for gce in can(length(module.attacker-gcp-infrastructure.config.context.gcp.gce)) ? module.attacker-gcp-infrastructure.config.context.gcp.gce : [] :
    [
      for compute in gce.instances : {
        id         = compute.instance.id
        name       = compute.instance.labels.name
        private_ip = compute.instance.network_interface.0.network_ip
        public_ip  = compute.instance.network_interface.0.access_config.0.nat_ip
        labels     = { for k, v in compute.instance.labels : k => v if v != "false" }
        project_id = var.attacker_gcp_project
        region     = var.attacker_gcp_region
      }
    ]
  ][0])
}