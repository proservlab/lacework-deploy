# Copyright 2019 Jetstack Ltd.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Resource definitions for cluster and node pools

# Each argument is explained, most details are pulled from the Terraform
# documentation. Arguments set by input variables are documented in the
# variables.tf file.

# Local values assign a name to an expression, that can then be used multiple
# times within a module. They are used here to determine the GCP region from
# the given location, which can be either a region or zone.
locals {
  gcp_location_parts = split("-", var.gcp_location)
  gcp_region         = format("%s-%s", local.gcp_location_parts[0], local.gcp_location_parts[1])
}

locals {
  release_channel    = var.release_channel == "" ? [] : [var.release_channel]
  min_master_version = var.release_channel == "" ? var.min_master_version : ""
  identity_namespace = var.identity_namespace == "" ? [] : [var.identity_namespace]
}

locals {
  authenticator_security_group = var.authenticator_security_group == "" ? [] : [var.authenticator_security_group]
}

resource "google_compute_network" "vpc_network" {
  name                    = "${var.vpc_network_name}-${var.environment}-${var.deployment}"
  auto_create_subnetworks = "false"
  project                 = var.gcp_project_id
}

# https://www.terraform.io/docs/providers/google/r/compute_subnetwork.html
resource "google_compute_subnetwork" "vpc_subnetwork" {
  # The name of the resource, provided by the client when initially creating
  # the resource. The name must be 1-63 characters long, and comply with
  # RFC1035. Specifically, the name must be 1-63 characters long and match the
  # regular expression [a-z]([-a-z0-9]*[a-z0-9])? which means the first
  # character must be a lowercase letter, and all following characters must be
  # a dash, lowercase letter, or digit, except the last character, which
  # cannot be a dash.
  #name = "default-${var.gcp_cluster_region}"
  name    = "${var.vpc_subnetwork_name}-${var.environment}-${var.deployment}"
  region  = local.gcp_region
  project = var.gcp_project_id

  ip_cidr_range = var.vpc_subnetwork_cidr_range

  # The network this subnet belongs to. Only networks that are in the
  # distributed mode can have subnetworks.
  network = var.vpc_network_name

  # Configurations for secondary IP ranges for VM instances contained in this
  # subnetwork. The primary IP of such VM must belong to the primary ipCidrRange
  # of the subnetwork. The alias IPs may belong to either primary or secondary
  # ranges.
  secondary_ip_range {
    range_name    = var.cluster_secondary_range_name
    ip_cidr_range = var.cluster_secondary_range_cidr
  }
  secondary_ip_range {
    range_name    = var.services_secondary_range_name
    ip_cidr_range = var.services_secondary_range_cidr
  }

  # When enabled, VMs in this subnetwork without external IP addresses can
  # access Google APIs and services by using Private Google Access. This is
  # set explicitly to prevent Google's default from fighting with Terraform.
  private_ip_google_access = true

  depends_on = [
    google_compute_network.vpc_network,
  ]
}

# https://www.terraform.io/docs/providers/google/r/compute_router.html
# This Cloud Router is used only for the Cloud NAT.
resource "google_compute_router" "router" {
  # Only create the Cloud NAT if it is enabled.
  count   = var.enable_cloud_nat ? 1 : 0
  name    = format("%s-router", "${var.cluster_name}-${var.environment}-${var.deployment}")
  region  = local.gcp_region
  network = google_compute_network.vpc_network.self_link
}

# https://www.terraform.io/docs/providers/google/r/compute_router_nat.html
resource "google_compute_router_nat" "nat" {
  # Only create the Cloud NAT if it is enabled.
  count = var.enable_cloud_nat ? 1 : 0
  name  = format("%s-nat", "${var.cluster_name}-${var.environment}-${var.deployment}")
  // Because router has the count attribute set we have to use [0] here to
  // refer to its attributes.
  router = google_compute_router.router[0].name
  region = google_compute_router.router[0].region
  # For this example project just use IPs allocated automatically by GCP.
  nat_ip_allocate_option = "AUTO_ONLY"
  # Apply NAT to all IP ranges in the subnetwork.
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = var.enable_cloud_nat_logging
    filter = var.cloud_nat_logging_filter
  }
}

# https://www.terraform.io/docs/providers/google/r/container_cluster.html
resource "google_container_cluster" "cluster" {
  location = var.gcp_location
  project = var.gcp_project_id

  name = "${var.cluster_name}-${var.environment}-${var.deployment}"

  min_master_version = local.min_master_version

  dynamic "release_channel" {
    for_each = toset(local.release_channel)

    content {
      channel = release_channel.value
    }
  }

  dynamic "authenticator_groups_config" {
    for_each = toset(local.authenticator_security_group)

    content {
      security_group = authenticator_groups_config.value
    }
  }

  # Configure workload identity if set
#   dynamic "workload_identity_config" {
#     for_each = toset(local.identity_namespace)

#     content {
#       identity_namespace = workload_identity_config.value
#     }
#   }

  maintenance_policy {
    daily_maintenance_window {
      start_time = var.daily_maintenance_window_start_time
    }
  }

  # A set of options for creating a private cluster.
  private_cluster_config {
    enable_private_endpoint = var.private_endpoint
    enable_private_nodes    = var.private_nodes

    master_ipv4_cidr_block = var.master_ipv4_cidr_block
  }

  # Enable the PodSecurityPolicy admission controller for the cluster.
#   pod_security_policy_config {
#     enabled = var.pod_security_policy_enabled
#   }

  # Configuration options for the NetworkPolicy feature.
  network_policy {
    # Whether network policy is enabled on the cluster. Defaults to false.
    # In GKE this also enables the ip masquerade agent
    # https://cloud.google.com/kubernetes-engine/docs/how-to/ip-masquerade-agent
    enabled = true

    # The selected network policy provider. Defaults to PROVIDER_UNSPECIFIED.
    provider = "CALICO"
  }

  master_auth {
    # Setting an empty username and password explicitly disables basic auth
    # username = ""
    # password = ""

    # Whether client certificate authorization is enabled for this cluster.
    client_certificate_config {
      issue_client_certificate = false
    }
  }

  # The configuration for addons supported by GKE.
  addons_config {
    http_load_balancing {
      disabled = var.http_load_balancing_disabled
    }

    # Whether we should enable the network policy addon for the master. This must be
    # enabled in order to enable network policy for the nodes. It can only be disabled
    # if the nodes already do not have network policies enabled. Defaults to disabled;
    # set disabled = false to enable.
    network_policy_config {
      disabled = false
    }
  }

  network    = var.vpc_network_name
  subnetwork = var.vpc_subnetwork_name

  # Configuration for cluster IP allocation. As of now, only pre-allocated
  # subnetworks (custom type with secondary ranges) are supported. This will
  # activate IP aliases.
  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  # It's not possible to create a cluster with no node pool defined, but we
  # want to only use separately managed node pools. So we create the smallest
  # possible default node pool and immediately delete it.
  remove_default_node_pool = true

  # The number of nodes to create in this cluster (not including the Kubernetes master).
  initial_node_count = 1

  # The desired configuration options for master authorized networks. Omit the
  # nested cidr_blocks attribute to disallow external access (except the
  # cluster node IPs, which GKE automatically whitelists).
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks_cidr_blocks
      content {
        cidr_block   = cidr_blocks.value.cidr_block
        display_name = cidr_blocks.value.display_name
      }
    }
  }

  # The loggingservice that the cluster should write logs to. Using the
  # 'logging.googleapis.com/kubernetes' option makes use of new Stackdriver
  # Kubernetes integration.
  logging_service = var.stackdriver_logging != "false" ? "logging.googleapis.com/kubernetes" : ""

  # The monitoring service that the cluster should write metrics to. Using the
  # 'monitoring.googleapis.com/kubernetes' option makes use of new Stackdriver
  # Kubernetes integration.
  monitoring_service = var.stackdriver_monitoring != "false" ? "monitoring.googleapis.com/kubernetes" : ""

  # Change how long update operations on the cluster are allowed to take
  # before being considered to have failed. The default is 10 mins.
  # https://www.terraform.io/docs/configuration/resources.html#operation-timeouts
  timeouts {
    update = "20m"
  }

  depends_on = [
    google_compute_subnetwork.vpc_subnetwork
  ]
}

# https://www.terraform.io/docs/providers/google/r/container_node_pool.html
resource "google_container_node_pool" "node_pool" {
  provider = google

  # The location (region or zone) in which the cluster resides
  location = google_container_cluster.cluster.location

  count = length(var.node_pools)

  # The name of the node pool. Instance groups created will have the cluster
  # name prefixed automatically.
  name = format("%s-pool", lookup(var.node_pools[count.index], "name", format("%03d", count.index + 1)))

  # The cluster to create the node pool for.
  cluster = google_container_cluster.cluster.name

  initial_node_count = lookup(var.node_pools[count.index], "initial_node_count", 1)

  # Configuration required by cluster autoscaler to adjust the size of the node pool to the current cluster usage.
  autoscaling {
    # Minimum number of nodes in the NodePool. Must be >=0 and <= max_node_count.
    min_node_count = lookup(var.node_pools[count.index], "autoscaling_min_node_count", 2)

    # Maximum number of nodes in the NodePool. Must be >= min_node_count.
    max_node_count = lookup(var.node_pools[count.index], "autoscaling_max_node_count", 3)
  }

  # Target a specific Kubernetes version.
  version = lookup(var.node_pools[count.index], "version", "")

  # Node management configuration, wherein auto-repair and auto-upgrade is configured.
  management {
    # Whether the nodes will be automatically repaired.
    auto_repair = lookup(var.node_pools[count.index], "auto_repair", true)

    # Whether the nodes will be automatically upgraded.
    auto_upgrade = lookup(var.node_pools[count.index], "version", "") == "" ? lookup(var.node_pools[count.index], "auto_upgrade", true) : false
  }

  # Parameters used in creating the cluster's nodes.
  node_config {
    # The name of a Google Compute Engine machine type. Defaults to
    # n1-standard-1.
    machine_type = lookup(
      var.node_pools[count.index],
      "node_config_machine_type",
      "n1-standard-1",
    )

    service_account = google_service_account.default.email

    # Size of the disk attached to each node, specified in GB. The smallest
    # allowed disk size is 10GB. Defaults to 100GB.
    disk_size_gb = lookup(
      var.node_pools[count.index],
      "node_config_disk_size_gb",
      100
    )

    # Type of the disk attached to each node (e.g. 'pd-standard' or 'pd-ssd').
    # If unspecified, the default disk type is 'pd-standard'
    disk_type = lookup(
      var.node_pools[count.index],
      "node_config_disk_type",
      "pd-standard",
    )

    # A boolean that represents whether or not the underlying node VMs are
    # preemptible. See the official documentation for more information.
    # Defaults to false.
    preemptible = lookup(
      var.node_pools[count.index],
      "node_config_preemptible",
      false,
    )

    # The set of Google API scopes to be made available on all of the node VMs
    # under the "default" service account. These can be either FQDNs, or scope
    # aliases. The cloud-platform access scope authorizes access to all Cloud
    # Platform services, and then limit the access by granting IAM roles
    # https://cloud.google.com/compute/docs/access/service-accounts#service_account_permissions
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    # The metadata key/value pairs assigned to instances in the cluster.
    metadata = {
      # https://cloud.google.com/kubernetes-engine/docs/how-to/protecting-cluster-metadata
      disable-legacy-endpoints = "true"
    }
  }

  # Change how long update operations on the node pool are allowed to take
  # before being considered to have failed. The default is 10 mins.
  # https://www.terraform.io/docs/configuration/resources.html#operation-timeouts
  timeouts {
    update = "20m"
  }
}

# Retrieve an access token as the Terraform runner
data "google_client_config" "provider" {}

data "google_container_cluster" "my_cluster" {
  name     = "${var.cluster_name}-${var.environment}-${var.deployment}"
  location = var.gcp_location

  depends_on = [
    google_container_node_pool.node_pool, google_container_cluster.cluster
  ]
}

resource "null_resource" "gke_context_switcher" {

  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "gcloud container clusters get-credentials ${var.cluster_name} --region=${var.gcp_location}"
  }

  depends_on = [
    google_container_cluster.cluster
  ]
}